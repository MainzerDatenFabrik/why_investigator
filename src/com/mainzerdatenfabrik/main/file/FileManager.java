package com.mainzerdatenfabrik.main.file;

import com.mainzerdatenfabrik.main.git.Git;
import com.mainzerdatenfabrik.main.logging.Logger;
import com.mainzerdatenfabrik.main.logging.slack.Slack;
import com.mainzerdatenfabrik.main.utils.Utils;
import com.mainzerdatenfabrik.main.json.JSONManager;
import org.json.JSONArray;
import com.mainzerdatenfabrik.main.library.Check;
import org.json.JSONObject;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.logging.Level;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

/**
 * Implementation of a com.mainzerdatenfabrik.main.file.FileManager to save JSONArray objects to file. The name of the file is based on a specific
 * format. Example: 20190325122000_HostName_CheckName -> '2019/03/25 12:20:00 HostName CheckName".
 *
 * @author Aaron Priesterroth
 * @
 */
public class FileManager {

    // Log-File file extension
    private static final String FILE_EXTENSION = ".log";
    // Compressed Log-File file extension
    private static final String FILE_EXTENSION_COMPRESSED = ".zip";

    // The name of the table for the connection error logs
    private static final String CONNECTION_ERRORS_TABLE = "Database-Connection-Errors";

    // Relative path to the log file directory
    private static final String LOG_FILE_DIRECTORY = "./logs";
    // Relative path to the log file directory for user queries from the log file directory
    private static final String USER_LOG_FILE_DIRECTORY = "/user";
    // Relative path to the log file directory for instance queries from the log file directory
    private static final String INSTANCE_LOG_FILE_DIRECTORY = "/instance";
    // Relative path to the log file directory for database queries from the log file directory
    private static final String DATABASE_LOG_FILE_DIRECTORY = "/database";
    // Relative path to the log file directory for the custom queries from the log file directory
    private static final String CUSTOM_LOG_FILE_DIRECTORY = "/custom";

    // What algorithm the messageDigest uses to generate hashes
    private static final String HASH_ALGORITHM = "SHA-256";

    // The default size of any byte buffer used
    private static final int BYTE_BUFFER_DEFAULT_SIZE = 1024;

    // The object parsed from the config file (lazy-initialized)
    private static JSONObject configurationObject;

    /**
     * Creates a JSONArray based on a specific timestamp, host name, port and database name and
     * saves it as a file. Used to create log files when an error occurs while connecting to a database.
     * The log file contains all information about the connection that failed.
     *
     * @param timestamp the specific timestamp (i.e., the current time)
     * @param hostName the specific host name
     * @param port the specific port number
     * @param databaseName the specific name of the database
     */
    public static void writeConnectionErrorLog(String workerName, String timestamp, String hostName, int port,
                                               String databaseName) {
        Logger.getLogger().info("Writing a connection error log for worker=" + workerName + ", " +
                "timestamp=" + timestamp + ", hostName=" + hostName + ", port=" + port + ", databaseName=" + databaseName + ".");

        // Create JSONArray containing JSONObject to save as file
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("Timestamp", timestamp);
        jsonObject.put("hostName", hostName);
        jsonObject.put("databaseName", databaseName);
        jsonObject.put("port", port);

        JSONArray jsonArray = new JSONArray();
        jsonArray.put(jsonObject);

        String datetimeid = Utils.getDatetimeId(timestamp);
        String fileName = datetimeid + "_" + hostName + "_" + databaseName + "_" + CONNECTION_ERRORS_TABLE;

        // Construct log directory string
        //String logDirectoryString = LOG_FILE_DIRECTORY + CUSTOM_LOG_FILE_DIRECTORY;
        String logDirectoryString = LOG_FILE_DIRECTORY + "/" + workerName + CUSTOM_LOG_FILE_DIRECTORY;

        // Retrieve log file directory as file
        File logDirectory = new File(logDirectoryString);

        // Create log file directory if it does not exist (+ parent directories)
        if(!logDirectory.exists()) {
            if(!logDirectory.mkdirs()) {
                Logger.getLogger().severe("Unable to create log directory: " + logDirectoryString + ".");
            }
        }

        // Creating the logFile itself
        File logFile = new File(logDirectory, fileName);

        // Opening a FileWriter to write a String to a specific file and saving the JSONArray converted
        // into a String with it.
        try(FileWriter file = new FileWriter(logFile)) {
            file.write(jsonArray.toString());
        } catch (IOException e) {
            Logger.getLogger().severe("Exception occurred while writing the ConnectionErrorLog for worker=" + workerName + ".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        Logger.getLogger().info("Finished writing ConnectionErrorLog for worker=" + workerName + ".");
    }

    /**
     * Converts a specific "ResultSet" into a json array and calls the saveToFileAsJSON(JSONArray, String, String,
     * String, Check) method.
     *
     * @param results the specific "ResultSet" that is converted into json format
     * @param timestamp the timestamp indicating date and time of the check execution
     * @param hostName the specific host name
     * @param databaseName the name of the database the query was executed on. Empty string is used if the query
     *                     was for no specific database (i.e., all instance/user queries)
     * @param check the check itself
     */
    public static void writeLog(String workerName, ResultSet results, String timestamp, String hostName,
                                        String databaseName, Check check) {
        Logger.getLogger().info("Converting ResultSet to json format.");
        writeLog(workerName, JSONManager.convertResultSet(results, timestamp), timestamp, hostName,
                databaseName, check);
    }

    /**
     * Creates a file and saves a specific JSONArray in it. The name of the file created is based on a timestamp
     * contained within the array that is being saved, a specific host name and the check itself, who's results are
     * being saved. Every created log is then recorded in the "Logfile history".
     *
     * @param array - the JSONArray containing the timestamp and being saved
     * @param timestamp - the timestamp indicating date and time of the check execution
     * @param hostName - the specific host name
     * @param databaseName - the name of the database the query was executed on. Empty string is used if the query
     *                     was for no specific database (i.e., all instance/user queries)
     * @param check - the check itself
     */
    public static void writeLog(String workerName, JSONArray array, String timestamp, String hostName, String databaseName, Check check) {
        Logger.getLogger().info("Writing log for worker=" + workerName + ", timestamp=" + timestamp + ", hostName="
                + hostName + ", databaseName=" + databaseName + ".");

        // Construct log file directory string
        //String logDirectoryString = LOG_FILE_DIRECTORY;
        String logDirectoryString = LOG_FILE_DIRECTORY + "/" + workerName;
        if(check != null) {
            switch (check.getType()) {
                case USER: logDirectoryString += USER_LOG_FILE_DIRECTORY; break;
                case INSTANCE: logDirectoryString += INSTANCE_LOG_FILE_DIRECTORY; break;
                case DATABASE: logDirectoryString += DATABASE_LOG_FILE_DIRECTORY; break;
                case CUSTOM: logDirectoryString += CUSTOM_LOG_FILE_DIRECTORY; break;
            }
        }

        // Retrieve log file directory as file
        File logDirectory = new File(logDirectoryString);

        // Create log file directory if it does not exist (+ parent directories)
        if(!logDirectory.exists()) {
            if(!logDirectory.mkdirs()) {
                Logger.getLogger().severe("Unable to create log directory: " + logDirectoryString + ".");
            }
        }

        // Construct file name
        String filename = constructFilename(timestamp, hostName, databaseName, check);

        // Creating the logFile itself
        File logFile = new File(logDirectory, filename);

        // Opening a FileWriter to write a String to a specific file and saving the JSONArray converted
        // into a String with it.
        try(FileWriter file = new FileWriter(logFile)) {
            file.write(array.toString());
        } catch (IOException e) {
            Logger.getLogger().severe("Exception occurred while writing the log for worker=" + workerName + ".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        Logger.getLogger().info("Finished writing log for worker=" + workerName + ".");
    }

    /**
     * Creates a filename based on a timestamp, a specific
     * host name and a specific query name and returns it.
     *
     * For the filename, every "_" or " " in the name of the query is substituted with a "-".
     *
     * @param  timestamp - the timestamp of the execution round of the com.mainzerdatenfabrik.main.worker thread
     * @param hostName - the specific host name
     * @param check - the specific
     *
     * @return - the created filename represented by a string
     */
    private static String constructFilename(String timestamp, String hostName, String databaseName, Check check) {
        String datetimeid = Utils.getDatetimeId(timestamp);

        // Filename friendly format (i.e., no "under scores" and "blanks" in the query names
        String cQueryName = "";
        if(check != null) {
            cQueryName = check.getName().replace(" ", "-").replace("_", "-");
        }

        return datetimeid + "_" + hostName + (databaseName.equals("") ? "" : "_" + databaseName) +
                (check == null ? "" : "_" + cQueryName) + FILE_EXTENSION;
    }

    /**
     * Creates a checksum of a specified string based on the "MessageDigest" instance at the top of the class.
     *
     * @param string the string to create the checksum of
     *
     * @return the checksum created from the specified string
     */
    public static String calculateChecksum(String string) {
       MessageDigest messageDigest = null;
        try {
            messageDigest = MessageDigest.getInstance(HASH_ALGORITHM);
        } catch (NoSuchAlgorithmException e) {
            Logger.getLogger().severe("Unable to find digest algorithm: " + HASH_ALGORITHM);
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }

        if(messageDigest != null) {

            byte[] bytes;
            byte[] byteString = string.getBytes();

            messageDigest.update(byteString, 0, byteString.length);

            bytes = messageDigest.digest();
            return buildHexString(bytes);
        }
        Logger.getLogger().severe("Failed to calculate checksum for: " + string);
        return null;
    }

    /**
     * Loads a file and creates the Checksum based on the "MessageDigest" instance at the top of the class.
     *
     * @param file - the file to get the checksum of
     *
     * @return - the checksum of the file
     */
    public static String calculateChecksum(File file) {
        Logger.getLogger().info("Calculating checksum for file: " + file.getName());

        MessageDigest messageDigest = null;
        try {
            messageDigest = MessageDigest.getInstance(HASH_ALGORITHM);
        } catch (NoSuchAlgorithmException e) {
            Logger.getLogger().severe("Unable to find digest algorithm: " + HASH_ALGORITHM);
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }

        if(messageDigest != null) {
            byte[] byteBuffer = new byte[BYTE_BUFFER_DEFAULT_SIZE];

            try (BufferedInputStream inputStream = new BufferedInputStream(new FileInputStream(file))) {

                int length;
                while((length = inputStream.read(byteBuffer)) >= 0) {
                    messageDigest.update(byteBuffer, 0, length);
                }
            } catch (IOException e) {
                Logger.getLogger().severe("Exception occurred while digesting file: " + file.getName());
                Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            }

            byte[] hash = messageDigest.digest();

            String hashString = buildHexString(hash);

            Logger.getLogger().info("Returning checksum: " + hashString + " for file: " + file.getName());
            return hashString;
        }
        Logger.getLogger().severe("Failed to calculate checksum for file: " + file.getName());
        return null;
    }

    /**
     * Build a hex string based on a specified array of bytes.
     *
     * @param bytes the array of bytes to build the hex string from
     *
     * @return the hex string created from the specified bytes array
     */
    private static String buildHexString(byte[] bytes) {
        StringBuilder hexString = new StringBuilder();

        for (byte b : bytes) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) {
                hexString.append("0");
            }
            hexString.append(hex);
        }
        return hexString.toString();
    }

    /**
     * Retrieves the host name of a file from the name of the file in the format "timestamp_hostname_checkname".
     *
     * @param file the file to retrieve the host name from
     *
     * @return the name of the host, null if the file name is not in the above format
     */
    public static String getHostName(File file) {
        String[] splitFileName = file.getName().split("_");
        if(splitFileName.length > 2) {
            return splitFileName[1];
        }
        return null;
    }

    /**
     * Creates a directory with the corresponding parent directories based on a specific path string.
     *
     * @param path the path string of the directory to create
     *
     * @return true, if directory exists or was created successfully, else false
     */
    public static boolean makeDirectory(String path) {
        File dir = new File(path);
        return makeDirectory(dir);
    }

    /**
     * Creates a directory with the corresponding parent directories based on a specific file.
     *
     * @param dir the specific file (directory) to create
     *
     * @return true, if directory exists or was created successfully, else false
     */
    public static boolean makeDirectory(File dir) {
        if(!dir.exists()) {
            return dir.mkdirs();
        }
        return true;
    }

    /**
     * Creates an array list of files contained in a specific directory.
     *
     * @param directory the specific directory
     *
     * @return the list of files inside of the directory, null if directory is null
     */
    public static ArrayList<File> getFilesFromDirectory(File directory, boolean includeDirs, List<String> blacklist) {
        if(directory == null) {
            return null;
        }

        ArrayList<File> files = new ArrayList<>();

        for(File file : directory.listFiles()) {

            if(blacklist.contains(file.getName())) {
                continue;
            }

            if(file.isDirectory()) {
                if(includeDirs) {
                    files.add(file);
                }
                files.addAll(getFilesFromDirectory(file, includeDirs, blacklist));
            } else {
                files.add(file);
            }
        }
        return files;
    }

    /**
     * Uses lazy initialization to load the config file as a JSONObject the first time it is used.
     *
     * @return the loaded config file as a JSONObject
     */
    private static JSONObject getConfigurationObject() {
        if(configurationObject == null) {
            configurationObject = new JSONObject(JSONManager.getJSONStringFromPath(Utils.PATH_TO_CONFIG_FILE));
        }
        return configurationObject;
    }

    /**
     * Used to retrieve a specific config object from the config file. For example, the config for the Git-Integration
     * can be accessed by the key "gitConfig".
     *
     * @param configName the name of the object inside of the config object to retrieve
     *
     * @return the config json object with key configName
     */
    public static JSONObject getConfigObject(String configName) {
        return getConfigurationObject().getJSONObject(configName);
    }

    /**
     * Used to retrieve a specific config array from the config file. For example, the SQlWorker config can be accessed
     * by the key "sqlWorkerConfig".
     *
     * @param configName the name of the array inside of the config object to retrieve
     *
     * @return the config json array with key configName
     */
    public static JSONArray getConfigArray(String configName) {
        return getConfigurationObject().getJSONArray(configName);
    }

    /**
     * Used to pack a file or whole directory. The format is based on the "zip" compression.
     *
     * @param sourceDirectoryPath the path of the file to pack
     * @param destDirectoryPath the path of where the packed file should be placed
     */
    public static void pack(String sourceDirectoryPath, String destDirectoryPath) {
        Logger.getLogger().info("Packing file: " + sourceDirectoryPath);

        Path destPath = null;
        try {
            destPath = Files.createFile(Paths.get(destDirectoryPath));
        } catch (IOException e) {
            Logger.getLogger().severe("Failed to create the destination file: " + destDirectoryPath);
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }

        if(destPath != null) {
            try(ZipOutputStream zipOut = new ZipOutputStream(Files.newOutputStream(destPath))) {

                Path sourcePath = Paths.get(sourceDirectoryPath);

                Files.walk(sourcePath)
                        .filter(path -> !Files.isDirectory(path))
                        .forEach(path -> {

                            ZipEntry zipEntry = new ZipEntry(sourcePath.relativize(path).toString());

                            try {
                                zipOut.putNextEntry(zipEntry);
                                Files.copy(path, zipOut);
                                zipOut.closeEntry();
                            } catch (IOException e) {
                                Logger.getLogger().severe("Failed to copy zipEntry into the zipStream.");
                                Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
                            }

                        });
            } catch (IOException e) {
                Logger.getLogger().severe("Failed to create the zipStream for packing file: " + sourceDirectoryPath);
                Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            }
        }
    }

    /**
     * Used to unpack a compressed file or whole directory. The format of the packed file/directory must be based on the
     * "zip" compression.
     *
     * When unpacking a file/directory, the unpacked copy of the file/directory is stored with the same name in the
     * local "LOG_FILE_DIRECTORY" directory.
     *
     * @param sourceDirectoryPath the path of the file/directory to unpack
     */
    public static String unpack(String sourceDirectoryPath) {
        Logger.getLogger().info("Unpacking file: " + sourceDirectoryPath);

        String directoryName;
        if(Utils.isWindowsOS()) {
            directoryName = sourceDirectoryPath.substring(sourceDirectoryPath.lastIndexOf("\\"), sourceDirectoryPath.lastIndexOf("."));
        } else {
            directoryName = sourceDirectoryPath.substring(sourceDirectoryPath.lastIndexOf("/"), sourceDirectoryPath.lastIndexOf("."));
        }

        File sourceDirectory = new File(sourceDirectoryPath);
        File unzippedDirectory = new File(LOG_FILE_DIRECTORY + "/" + directoryName);
        if(!Files.exists(Paths.get(unzippedDirectory.getAbsolutePath()))) {
            unzippedDirectory.mkdirs();
        }

        ZipFile zipFile = null;

        try {
            zipFile = new ZipFile(sourceDirectory);

            Enumeration<? extends ZipEntry> enumeration = zipFile.entries();

            while(enumeration.hasMoreElements()) {
                ZipEntry entry = enumeration.nextElement();

                File destination = new File(unzippedDirectory.getAbsolutePath(), entry.getName());

                destination.getParentFile().mkdirs();

                //if entry is file extract it
                if(!entry.isDirectory()) {

                    int b;
                    byte[] buffer = new byte[1024];

                    BufferedInputStream bufferedInputStream = new BufferedInputStream(zipFile.getInputStream(entry));
                    FileOutputStream fileOutputStream = new FileOutputStream(destination);
                    BufferedOutputStream bufferedOutputStream = new BufferedOutputStream(fileOutputStream, buffer.length);

                    while((b = bufferedInputStream.read(buffer, 0, buffer.length)) != -1) {
                        bufferedOutputStream.write(buffer, 0, b);
                    }

                    bufferedOutputStream.close();
                    bufferedInputStream.close();
                }
            }

        } catch (IOException e) {
            Logger.getLogger().severe("Failed to unpack file: " + sourceDirectoryPath);
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        } finally {
            if(zipFile != null) {
                try {
                    zipFile.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        Logger.getLogger().info("File " + sourceDirectoryPath + " unpacked to: " + unzippedDirectory.getAbsolutePath());
        return unzippedDirectory.getAbsolutePath();
    }

    /**
     * Used to delete a directory with all the files it contains.
     *
     * @param directoryString the path of the directory to delete
     */
    public static void cleanDirectory(String directoryString, boolean deleteDirectory) {
        Logger.getLogger().info("Cleaning directory: " + directoryString + ". Deleting the directory after: " + deleteDirectory + ".");
        File directory = new File(directoryString);
        cleanDirectory(directory);
        if(deleteDirectory) {
            directory.delete();
        }
    }

    /**
     * Used to recursively delete all files inside of a specific directory.
     *
     * @param root the specific directory to delete all files from
     */
    public static void cleanDirectory(File root) {
        if(root.isDirectory() && root.listFiles() == null) {
            return;
        }
        for(File file : root.listFiles()) {
            if(file.isDirectory()) {
                cleanDirectory(file);
            }
            file.delete();
        }
    }

    /**
     * Used to delete the directory of a worker with all the files it contains based on the workers name.
     *
     * @param workerName the name of the worker, i.e., the name of the directory
     */
    public static void cleanWorkerDirectory(String workerName, boolean deleteDirectory) {
       cleanDirectory(LOG_FILE_DIRECTORY + "/" + workerName, deleteDirectory);
    }

    /**
     * Used to determine if the directory of a worker exists or not.
     *
     * @param workerName the name of the worker, i.e., the name of the directory
     *
     * @return true if the directory exists, else false
     */
    public static boolean workerDirExists(String workerName) {
        return Files.exists(Paths.get(LOG_FILE_DIRECTORY + "/" + workerName));
    }

    /**
     * Used to process the workers directory of a specific worker identified by the workerName. The workers directory
     * is packed and moved into the git repository. After, the files is added, committed and pushed.
     * Finally, the workers directory is deleted to remove the local files.
     *
     * @param workerName the name of the worker identifying the directory
     * @param hostname the name of the host the data is collected from
     * @param timestamp the timestamp for the iteration of the data
     */
    public static void processWorkersDirectory(String workerName, String subDirectory, String hostname, String timestamp, String projectHashId) {
        Logger.getLogger().info("Processing worker directory for worker=" + workerName + " in dir=" + subDirectory
                        + ", hostName=" + hostname + ", timestamp=" + timestamp + ".");

        String datetimeid = Utils.getDatetimeId(timestamp);
        String fileName = datetimeid + "_" + Utils.randomAlphaNumericString(20) + "_" + projectHashId + "_" + hostname + FILE_EXTENSION_COMPRESSED;
        String destination = Git.getGitRepositoryLocalPath() + "/" + subDirectory + "/" + fileName;
        String source = LOG_FILE_DIRECTORY + "/" + workerName;
        pack(source, destination);

        String branchName = workerName + "_" + datetimeid;

        if(!Git.status()) {
            Logger.getLogger().info("Adding, committing and pushing data gathered by worker=" + workerName + ".");
            Git.checkoutNewBranch(branchName);
            Git.pushSetUpstream(branchName);
            Git.add(destination);
            Git.commit("Worker " + workerName + " committing logs with datetimeid=" + datetimeid + ".");
            Git.push();
            Git.checkoutMaster();
            Git.merge(branchName);
            Git.push();
        } else {
            Logger.getLogger().warning("Nothing to commit from worker=" + workerName + " in dir=" + subDirectory
                    + ", hostName=" + hostname + ", timestamp=" + timestamp + ".");
        }
        Logger.getLogger().info("Cleaning worker directory for worker=" + workerName);
        cleanWorkerDirectory(workerName, true);
        Logger.getLogger().info("Finished processing worker directory for worker=" + workerName + ".");
    }

    /**
     * Moves a specific file from its current location into a different folder specified by folderPathString.
     *
     * @param file the file that is moved
     * @param folderPathString the path string to the new location
     */
    public static void moveFile(File file, String folderPathString) {
        File directory = new File(folderPathString);
        if(!directory.exists() && !directory.mkdir()) {
            Logger.getLogger().severe("Failed to create the directory: " + folderPathString + ".");
        }
        try {
            Files.move(file.toPath(), new File(directory, file.getName()).toPath(), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            Logger.getLogger().severe("Failed to move file " + file.getName() + ".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);

            Slack.sendMessage("*Processor*: Failed to move the file " + file.getName() + " (*" + e.getMessage() + "*).");
        }
    }

    /**
     * Retrieves the name of the table based on a specific file (i.e., gets the check name that created the file
     * and strips the "-" from it.
     *
     * @param file the specific file
     *
     * @return the table name derived from the file
     */
    public static String getTableNameFromFile(File file) {
        String[] splitFileName = file.getName().split("_");
        return splitFileName[splitFileName.length - 1].split("\\.")[0].replace("-", "");
    }

    /**
     * Reads a file specified by its path and returns the content as a string.
     *
     * @return the string string retrieved from the content of the specified file
     */
    public static String readFile(String path) {
        StringBuilder builder = new StringBuilder();

        try(BufferedReader reader = new BufferedReader(new FileReader(path))) {
            String line;
            while((line = reader.readLine()) != null) {
                builder.append(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return builder.toString();
    }
}






























