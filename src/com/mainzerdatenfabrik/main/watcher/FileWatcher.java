package com.mainzerdatenfabrik.main.watcher;

import com.mainzerdatenfabrik.main.logging.Logger;
import com.mainzerdatenfabrik.main.logging.slack.Slack;
import com.mainzerdatenfabrik.main.utils.Utils;
import com.mainzerdatenfabrik.main.file.FileManager;
import com.mainzerdatenfabrik.main.module.ProgramModule;
import com.mainzerdatenfabrik.main.shell.Shell;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.util.*;
import java.util.logging.Level;
import java.util.regex.Pattern;

/**
 * The FileWatcher is basically a simple file crawler, observing one specified directory with all the files it contains.
 * The scanning of the files happens in frequent iterations, where with every iteration the current status of every file
 * contained in the observed directory is recorded with its attributes like permissions, owner, modify date, etc.,
 * with some specified time in between iterations.
 */
public class FileWatcher extends ProgramModule {

    // A list of filenames the FileWatcher instance shall ignore when scanning the observed directory
    private static final ArrayList<String> FILE_BLACKLIST = new ArrayList<>(List.of("FileWatcher"));

    // The name of the directory the file watcher is putting its logs into
    private static final String FILE_WATCHER_DIRECTORY = "FileWatcher";

    private String observedDirectoryName;

    private String serverName;

    private int sleepTime;

    /**
     * The Constructor.
     *
     * The config file specified in "Utils.PATH_TO_CONFIG_FILE" is loaded.
     */
    public FileWatcher() {
        super("FileWatcher");

        loadConfig();
    }

    /**
     * The overwritten run method as this class is an instance of class "Thread", containing the procedure of the
     * program.
     */
    @Override
    public void run() {

        File observedDirectory = new File(this.observedDirectoryName);

        if(!FileManager.makeDirectory(observedDirectory)) {
            Logger.getLogger().severe("The directory to observe does not exist and the creation failed.");
            return;
        }

        try {
            while(running) {
                active = true;

                // Clean up the worker directory of the FileWatcher instance if the directory already exists
                if(FileManager.workerDirExists(FILE_WATCHER_DIRECTORY)) {
                    FileManager.cleanWorkerDirectory(FILE_WATCHER_DIRECTORY, false);
                }


                String timestamp = Utils.DATE_TIME_FORMAT.format(new Date());

                String hostName = "";
                JSONObject ipConfigObject = new JSONObject();
                HashMap<String, String> ipConfigAttributes = parseIpConfigAttributes();
                for(Map.Entry<String, String> entry : ipConfigAttributes.entrySet()) {
                    if(entry.getKey().contains("Hostname")) {
                        hostName = entry.getValue();
                    }
                    ipConfigObject.put(entry.getKey(), entry.getValue());
                }

                // Retrieve all files from the directory being observed
                ArrayList<File> retrievedFiles =
                        FileManager.getFilesFromDirectory(observedDirectory, true, FILE_BLACKLIST);

                // Keep track of the amount of processed files
                int processedFiles = 0;
                // Keep track of the amount of time it took to process all files by creating a timestamp
                java.util.Date startDatetime = new java.util.Date();

                //Slack status message
                Slack.sendMessage("*FileWatcher*: Found *" + retrievedFiles.size() + "* files to process.");

                for(File file : retrievedFiles) {
                    // If fileWatcher is in between processing a group of files and the user is terminating the module
                    // the fileWatcher should finish his current file, but not continue with the next ones.
                    if(!running) break;

                    //Slack status message
                    Slack.sendMessage("*FileWatcher*: Starting to process file *" + (processedFiles + 1) + " of " + retrievedFiles.size() + "*.");

                    // Create a copy of the ipConfigObject to make every jsonObject have all the attributes
                    // retrieved from the ipConfig (must be uniform for insertion into the table)
                    JSONObject fileInfo = new JSONObject(ipConfigObject.toString());

                    fileInfo.put("Timestamp", timestamp);
                    fileInfo.put("ServerName", serverName);
                    fileInfo.put("isDirectory", file.isDirectory());
                    fileInfo.put("sizeInBytes", file.length());
                    fileInfo.put("lastModified", Utils.LAST_MODIFIED_DATE_TIME_FORMAT.format(file.lastModified()));
                    fileInfo.put("path", file.getAbsolutePath());
                    // Todo: "checksum" is not a valid name as it is a keyword in sql
                    if(!file.isDirectory()) {
                        fileInfo.put("fileHash", FileManager.calculateChecksum(file));
                    } else {
                        fileInfo.put("fileHash", "NULL");
                    }

                    // On windows os
                    if(Utils.isWindowsOS()) {
                        String permissionString = Shell.executeInfoCommand("icacls", file.getAbsolutePath());
                        fileInfo.put("permissions", Shell.formatPermissionString(permissionString));
                        String permissionParentString = Shell.executeInfoCommand("icacls", file.getParentFile().getAbsolutePath());
                        fileInfo.put("parentPermission", Shell.formatPermissionString(permissionParentString));
                    // On linux os
                    } else {
                        // Todo: Get POSIX attributes of file
                    }
                    fileInfo.put("fileName", file.getName());
                    fileInfo.put("fileExtension", getFileExtension(file));

                    // Todo: "_FileWatcher" has to be appended so the processor knows which table to put the data in
                    FileManager.writeLog(FILE_WATCHER_DIRECTORY, new JSONArray().put(fileInfo), timestamp, hostName,
                            sanitizeFileName(file) + "_FileWatcher", null);

                    processedFiles++;
                }

                // If any new files were processed
                if(processedFiles > 0) {
                    java.util.Date endDatetime = new java.util.Date();

                    //Slack status message
                    Slack.sendMessage("*FileWatcher*: Finished processing " + processedFiles + " of " + retrievedFiles.size() + " files!");
                    Slack.sendMessage("*FileWatcher*: The processing of " + processedFiles + " files was started at "
                            + startDatetime + " and ended at " + endDatetime + " (*"
                            + ((endDatetime.getTime() - startDatetime.getTime())/60000.0) + " minutes* total).");
                }

                // TODO: Fix FileWatcher ProjectHashId
                String projectHashId = "NULL";
                FileManager.processWorkersDirectory(FILE_WATCHER_DIRECTORY, "FileWatcher", hostName, timestamp, projectHashId);

                // If the watcher is "supposed" to continue running
                if(running) {
                    active = false;

                    //Slack status message
                    Slack.sendMessage("*FileWatcher*: Sleeping for *" + sleepTime + "* minutes.");
                    Logger.getLogger().info("Sleeping for " + sleepTime + " minutes.");

                    Thread.sleep(Utils.MS_PER_MIN * sleepTime);
                }
            }
        } catch (InterruptedException e) {
            Logger.getLogger().severe("The FileWatcher was interrupted.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        Logger.getLogger().info("FileWatcher EXIT.");
    }

    /**
     * Used to retrieve the extension of a file in string format.
     *
     * @param file the file to retrieve the file extension from
     *
     * @return the file extension of the specified file in string format
     */
    private String getFileExtension(File file) {
        String extension = "";
        if(file.getName().contains(".")) {
            extension = file.getName().substring(file.getName().lastIndexOf(".")+1);
        }
        return extension;
    }

    /**
     * Used to sanitize and return the name of a specific file from all illegal characters, such as "'".
     *
     * @param file the file two get the sanitized name from
     *
     * @return the sanitized file name
     */
    private String sanitizeFileName(File file) {
        String name = file.getName()
                .replaceAll("'", "");
        return name;
    }

    /**
     * Parses the information returned by executing the "ipConfig" command on the windows console as a HashMap.
     *
     * @return a hash map consisting of attribute name - attribute value pairs
     */
    // Todo: get all the attributes from the command, not only hostName
    private HashMap<String, String> parseIpConfigAttributes() {
        HashMap<String, String> map = new HashMap<>();

        String ipConfigString = Shell.executeInfoCommand("ipconfig", "/all");
        ipConfigString = Utils.replaceUmlauts(ipConfigString);

        String[] ipConfigSplit = ipConfigString.split("\n\n");

        // Loop over every other object of the array, as the objects with even index are only headers
        // and the objects with odd index contain relevant information
        for(int i = 1; i < ipConfigSplit.length; i += 2) {
            String[] sectionSplit = ipConfigSplit[i].split("\n");
            String attributeName = "";
            String attributeValue = "";

            String attributePrefix = getPrefixFromHeader(ipConfigSplit [i-1]);

            for(int j = 0; j < sectionSplit.length; j++) {
                String line = sectionSplit[j];
                // Regex: for the ipconfig command format of "attributeName . . . . . . . : attributeValue"
                // Regex: Zero or more occurrences of " .", Zero or more occurrences of " " followed by ":"
                String[] split = line.split("(\\s\\.)*\\s*:", 2);

                if(split.length == 2) {
                    attributeName = attributePrefix + split[0].trim();
                    attributeValue = split[1].trim();

                    int attributeNameThreshold = 15;

                    // Fail-safe for DNS-Server attribute
                    // If the length of the attribute name is short (< 15 chars) and there is no " . . . . . :"
                    // contained, it is not a new attribute but rather a new line and needs to be appended
                    String regex = "(\\s\\.)+";
                    if(attributeName.length() < attributeNameThreshold && !Pattern.matches(regex, line)) {
                        // needs to be appended to the previous attribute
                        map.put(attributeName, map.get(attributeName) + line.trim());
                    } else {
                        map.put(attributeName, attributeValue);
                    }
                } else {
                    map.put(attributeName, map.get(attributeName) + line);
                }
            }
        }
        return map;
    }

    /**
     * Retrieves the prefix for an attribute name from a specific header string.
     *
     * @param header the header to retrieve the prefix from
     *
     * @return the prefix retrieved from the header
     */
    private String getPrefixFromHeader(String header) {
        String prefix = header.replace("-IP-Konfiguration", "")
                .replace("-Adapter Ethernet:", "")
                .replace("Drahtlos-LAN-Adapter ", "")
                .replace("Drahtlos-LAN-Adapter ", "")
                .replace("Ethernet-Adapter ", "")
                .replace("-Netzwerkverbindung:", "")
                .replace(" Network Adapter ", "");

        prefix = prefix.replace("\n", "")
                .replace(":", "");

        return prefix + " ";
    }

    /**
     * Loads the config file and parses "observedDirectory" and "sleepTime" from it.
     */
    protected void loadConfig() {
        Logger.getLogger().config("Loading the FileWatcher config.");

        // Retrieve "workerConf" object from config json
        JSONObject walkerConfig = FileManager.getConfigObject("fileWatcherConfig");

        observedDirectoryName = walkerConfig.getString("observedDirectory");
        Logger.getLogger().config("Retrieved observedDirectory=" + observedDirectoryName + " from config.");
        serverName = walkerConfig.getString("serverName");
        Logger.getLogger().config("Retrieved serverName=" + serverName + " from config.");
        sleepTime = walkerConfig.getInt("sleepTime");
        Logger.getLogger().config("Retrieved sleepTime=" + sleepTime + " from config.");

        //Slack status message
        Slack.sendMessage("*FileWatcher*: Observing the directory *" + observedDirectoryName + "* on the *" + serverName
                + "* server. The delay between iterations is *" + sleepTime + " minutes*.");

        Logger.getLogger().config("Finished loading FileWatcher config.");
    }
}
