package com.mainzerdatenfabrik.main.processor;

import com.mainzerdatenfabrik.main.file.FileManager;
import com.mainzerdatenfabrik.main.git.Git;
import com.mainzerdatenfabrik.main.json.JSONManager;
import com.mainzerdatenfabrik.main.library.CheckLibrary;
import com.mainzerdatenfabrik.main.logging.Logger;
import com.mainzerdatenfabrik.main.logging.slack.Slack;
import com.mainzerdatenfabrik.main.module.ProgramModule;
import com.mainzerdatenfabrik.main.utils.UtilsJDBC;
import com.mainzerdatenfabrik.main.utils.Utils;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.sql.Date;
import java.sql.*;
import java.util.*;
import java.util.logging.Level;

/**
 * Implementation of the Processor. The program is listening on a directory for new files. Whenever a new file is
 * found, the data of the file is inserted into a corresponding database table. If successful, the file is moved into
 * a "out" directory. Else, the file is moved into a "error" directory.
 * Every file entering the observed directory is also recorded in a special table with its checksum.
 *
 * @author Aaron Priesterroth
 */
public class Processor extends ProgramModule {

    // NVARCHAR(MAX)
    // The list of column names that need the size MAX instead of some fixed size
    private static final ArrayList<String>  N_VARCHAR_MAX_LIST = new ArrayList<>(List.of("script"));

    private static final String PROCEDURE_GENERATE_FACT = "exec [fact].[generate]";

    private static final ArrayList<String>  FILE_BLACKLIST = new ArrayList<>(List.of("Processed", ".git"));

    // The directory that is scanned for files
    private String fileDirectory;
    // The path of the directory that files are moved to after an unsuccessful insert
    private String errorDirectory;
    // The path of the directory that files are moved to after a successful insert
    private String outDirectory;
    // The name of the host to connect to
    private String hostName;
    // The database the data is written into
    private String targetDatabaseName;

    // The port to connect on
    private int port;
    // The amount of time to sleep between cycles of checking for new files in ms.
    private int sleepTime;

    // The sql username and password used to authenticate when connecting to the target database
    // the processor is writing the data to. If empty (i.e., sqlUsername = ""), ad authentication is used.
    private String sqlUsername;
    private String sqlPassword;

    /**
     * The Constructor.
     *
     * The config file specified in "Utils.PATH_TO_CONFIG_FILE" is loaded.
     */
    public Processor() {
        super("Processor");

        loadConfig();
    }

    /**
     * Creates the "FileProtocol" table if it does not already exist.
     *
     * @param connection the connection used for communication with the database
     *
     * @return true, if the "FileProtocol" table already exists or was created successfully, else false
     */
    private boolean setupProtocolTable(Connection connection) {
        try(Statement statement = connection.createStatement()) {
            // Check if the table is already present in database
            if(retrieveTableNames(connection).contains(UtilsJDBC.PROTOCOL_TABLE_NAME)) {
                return true;
            }

            //Slack status message
            Slack.sendMessage("*Processor*: The *\"Protocol table\"* is missing. Creating it now.");
            Logger.getLogger().info("Creating the missing protocol table.");

            return statement.executeUpdate(CheckLibrary.CREATE_PROTOCOL_TABLE.getQuery()) >= 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    /**
     * The overwritten run method as this class is an instance of class "Thread", containing the procedure of the
     * program.
     */
    @Override
    public void run() {
        try(Connection connection = UtilsJDBC.establishConnection(hostName, port, targetDatabaseName, sqlUsername, sqlPassword)) {
            active = true;
            File observedDirectory = new File(fileDirectory);
            // Make sure the directory to observer exists or create it if not
            // exit the program if there was an error creating it
            //File fileDirectory = new File(this.fileDirectory);
            //if(!FileManager.makeDirectory(fileDirectory)) {
            //    Logger.getLogger().severe("Failed to create the " + this.fileDirectory + " directory.");
            //    return;
            //}

            // Check if the "stage" schema exists and create it if it does not
            if(!setupDBSchema(connection)) {
                Logger.getLogger().warning("Failed to create the stage schema!");
                return;
            }

            // Check if the "protocol" table exists and create it if it does not
            if(!setupProtocolTable(connection)) {
                Logger.getLogger().warning("Failed to create the FileProtocols table!");
                return;
            }

            while(running) {
                // Retrieve all "zip" files from the observed directory
                ArrayList<File> files = FileManager.getFilesFromDirectory(observedDirectory, false, FILE_BLACKLIST);

                // Keep track of the amount of processed files
                int processedFiles = 0;
                // Keep track of the amount of time it took to process all files by creating a timestamp
                java.util.Date startDatetime = new java.util.Date();

                //Slack status message
                Slack.sendMessage("*Processor*: Found *" + files.size() + "* files to process.");

                for(File file : files) {
                    // If processor is in between processing a group of files and the user is terminating the module
                    // the processor should finish his current file, but not continue with the next ones.
                    if(!running) break;

                    //Slack status message
                    Slack.sendMessage("*Processor*: Starting to process file *" + (processedFiles + 1) + " of " + files.size() + "*.");

                    //Process every "zip" file that was found
                    if(processZipFile(connection, file)) {

                        FileManager.moveFile(file, outDirectory);
                    } else {
                        FileManager.moveFile(file, errorDirectory);
                    }
                    processedFiles++;
                }

                // If any new files were processed
                if(processedFiles > 0) {
                    java.util.Date endDatetime = new java.util.Date();

                    //Slack status message
                    Slack.sendMessage("*Processor*: Finished processing " + processedFiles + " of " + files.size() + " files!");
                    Slack.sendMessage("*Processor*: The processing of " + processedFiles + " files was started at "
                            + startDatetime + " and ended at " + endDatetime + " (*"
                            + ((endDatetime.getTime() - startDatetime.getTime())/60000.0) + " minutes* total).");

                    // Push processed files to a new branch and merge the branch with master
                    Git.pushToBranchAndMerge("Processor");

                    // Start the fact/dim generation
                    generateFacts(connection);
                }

                // If the processor is "supposed" to continue running
                if(running) {
                    active = false;

                    //Slack status message
                    Slack.sendMessage("*Processor*: Sleeping for *" + sleepTime + "* minutes.");
                    Logger.getLogger().info("Sleeping for " + sleepTime + " minutes.");

                    Thread.sleep(Utils.MS_PER_MIN * sleepTime);
                }
            }
        } catch (SQLException e) {
            //Slack status message
            Slack.sendMessage("*Processor*: Failed to establish a connection to: *" + hostName + "/" + targetDatabaseName + "*.");
            Logger.getLogger().severe("Unable to establish a connection to: " + hostName + "/" + targetDatabaseName);
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        } catch (InterruptedException e) {
            Logger.getLogger().info("Processor was interrupted while sleeping.");
            Logger.getLogger().info("Processor EXIT.");
        }
    }

    /**
     * Executes the stored t-sql procedure called "[fact].[generate]"
     */
    private void generateFacts(Connection connection) {
        try {
            Statement statement = connection.createStatement();
            statement.executeQuery(PROCEDURE_GENERATE_FACT);

            Logger.getLogger().info("Executing \"exec [fact].[generate]\" now...");
            //Slack status message
            Slack.sendMessage("*Processor*: *Executing* the t-SQL procedure *PROCEDURE_GENERATE_FACT*!");
        } catch (SQLException e) {
            Slack.sendMessage("*Processor*: Failed to execute the t-SQL procedure *PROCEDURE_GENERATE_FACT* (" + e.getMessage() + ")!");
            Logger.getLogger().severe("Failed to execute the t-sql procedure \"PROCEDURE_GENERATE_FACT\".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
    }

    /**
     * Check if a specific file is present (i.e., already registered) in the "Protocol table".
     *
     * @param connection the connection the query is executed on to check if the table contains the file
     * @param file the specific file that is being registered
     * @param projectHashId the projectHashId corresponding to the file
     *
     * @return true, if the registration was successfully. False if the file already is registered,  the file is empty
     *          or the insertion itself failed
     */
    private boolean registerFile(Connection connection, File file, String projectHashId) {
        // Calculate the fileHash (i.e., the Checksum of the file)
        String checksum = FileManager.calculateChecksum(file);

        try(Statement statement = connection.createStatement()) {
            String query = CheckLibrary.PROTOCOL_TABLE_CONTAINS_FILE.getQuery() + "\'" + checksum + "\';";
            if(statement.executeQuery(query).isBeforeFirst()) {
                return false;
            }

            String insertQuery = "INSERT INTO stage." + UtilsJDBC.PROTOCOL_TABLE_NAME + " VALUES (";
            JSONArray jsonArray = JSONManager.getJSONArrayFromFile(file);
            if(jsonArray == null) {
                Logger.getLogger().warning("File is empty: " + file.getName());
                Logger.getLogger().warning("Skipping empty file: " + file.getName());
                return false;
            }
            insertQuery += JSONManager.getDateTimeId(jsonArray) + ", ";
            insertQuery += "\'" + FileManager.getHostName(file) + "\'" + ", ";
            insertQuery += "\'" + file.getName() + "\'" + ", ";
            insertQuery += "\'" + FileManager.calculateChecksum(file) + "\'" + ", ";
            insertQuery += "\'" + Git.getGitRepositoryURL() + "/Processed/" + file.getName() + "\', ";
            insertQuery += "\'" + projectHashId + "\');";

            return statement.executeUpdate(insertQuery) > 0;
        } catch (SQLException e) {
            Logger.getLogger().severe("Failed to check/register a file in the protocol table.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return false;
    }

    /**
     * Processes a specific "zip" compressed file by unpacking it and processing every file (i.e. log) that is contained
     * in the specific "zip" file. In this process, every file is registered
     *
     * @param connection the connection to a specific database/database-table to process and register the files with
     * @param file the specific "zip" compressed file to process
     *
     * @return true, if the processing/registration was successful for every file, else false
     */
    private boolean processZipFile(Connection connection, File file) {
        String unpackedPath = FileManager.unpack(file.getAbsolutePath());
        File unpacked = new File(unpackedPath);

        // The unique hash value identifying the group of files packed in the "zip" file.
        String projectHashId = FileManager.calculateChecksum(file);

        // The datetimeid of the start of reading in the zip file
        String datetimeid = Utils.getDatetimeId();

        ArrayList<File> retrievedFiles = FileManager.getFilesFromDirectory(unpacked, false, FILE_BLACKLIST);

        // Set of the names of all tables within the database
        Set<String> tableNames = retrieveTableNames(connection);

        for(File currentFile : retrievedFiles) {
            if(!registerFile(connection, currentFile, projectHashId)) {
                Logger.getLogger().warning("File " + currentFile.getName() + " could not be registered.");
                continue;
            } else {
                Logger.getLogger().info("Registered file " + currentFile.getName() + " successfully.");
            }

            // The table name based on the current file
            String tableName = getTableNameFromFile(currentFile);

            // Create the table for the current file if it does not exit yet
            if(!tableNames.contains(tableName)) {
                Logger.getLogger().warning("Creating table: " + tableName + ".");
                if(createTableFromFile(connection, tableName, currentFile)) {
                    tableNames.add(tableName);
                } else {
                    Logger.getLogger().warning("Failed to create the " + tableName + " table!");
                }
            }

            // Insert values from the file into the table
            // If insertion was successful, move the file to the "out" directory
            // If insertion failed, return false to indicate that the file must be moved into the "error" directory
            if(insertFileIntoTable(connection, currentFile, tableName, projectHashId)) {
                Logger.getLogger().info("Successfully inserted data from file: " + currentFile.getName());
            } else {
                Logger.getLogger().warning("Failed to insert data from file: " + file.getName());
                return false;
            }
        }
        // Delete the local files that were just processed
        FileManager.cleanDirectory(unpackedPath, true);

        // Indicate that the whole "zip" file was processed successfully
        return true;
    }

    /**
     * Loads the config file and parses "fileDirectory", "errorDirectory", "outDirectory", "hostName",
     * "targetDatabaseName" and "sleepTime" from it.
     */
    protected void loadConfig() {
        Logger.getLogger().config("Loading the Processor config.");

        // Retrieve "workerConfig" object from config
        JSONObject workerConfig = FileManager.getConfigObject("processorConfig");

        // Todo: how to handle this? Maybe make a switch if git is not used?
        //observedDirectory = Git.getGitRepositoryLocalPath();
        fileDirectory = workerConfig.getString("fileDirectory");
        Logger.getLogger().config("Retrieved fileDirectory=" + fileDirectory + " from config.");
        errorDirectory = workerConfig.getString("errorDirectory");
        Logger.getLogger().config("Retrieved errorDirectory=" + errorDirectory + " from config.");
        outDirectory = workerConfig.getString("outDirectory");
        Logger.getLogger().config("Retrieved outDirectory=" + outDirectory + " from config.");

        hostName = workerConfig.getString("hostName");
        Logger.getLogger().config("Retrieved hostName=" + hostName + " from config.");
        targetDatabaseName = workerConfig.getString("targetDatabaseName");
        Logger.getLogger().config("Retrieved targetDatabaseName=" + targetDatabaseName + " from config.");

        // Retrieve the port to connect on
        // If the config specifies no port, the default port 1433 is used
        port = Utils.DEFAULT_PORT;
        if(workerConfig.keySet().contains("port")) {
            port = workerConfig.getInt("port");
        }
        Logger.getLogger().config("Retrieved port=" + port + " from config.");
        sqlUsername = workerConfig.getString("username");
        Logger.getLogger().config("Retrieved sqlUsername=" + sqlUsername + " from config.");
        sqlPassword = workerConfig.getString("password");
        Logger.getLogger().config("Retrieved sqlPassword=" + sqlPassword + " from config.");
        sleepTime = workerConfig.getInt("sleepTime");
        Logger.getLogger().config("Retrieved sleepTime=" + sleepTime + " from config.");

        //Slack status message
        Slack.sendMessage("*Processor*: Processing files to *" + hostName + "* on port *" + port + "* into the *"
                + targetDatabaseName + "* database. The delay between processing iterations is *" + sleepTime + " minutes*.");
        Logger.getLogger().config("Finished loading Processor config.");
    }

    /**
     * Executes an insert statement based on a specific tableName and a specific file containing the date to insert.
     *
     * @param file the specific table name
     * @param tableName the specific file
     *
     * @return true, if successful, false if not
     */
    private boolean insertFileIntoTable(Connection connection, File file, String tableName, String projectHashId) {
        // Retrieve the JSONArray from file
        JSONArray jsonArray = JSONManager.getJSONArrayFromFile(file);

        // Skip processing the file if it is empty
        if(jsonArray == null) {
            Logger.getLogger().warning("File is empty: " + file.getName());
            Logger.getLogger().warning("Skipping empty file: " + file.getName());
            return false;
        }

        // Retrieve the "datetimeid" from the jsonArray
        String datetimeid = JSONManager.getDateTimeId(jsonArray);

        try(Statement statement = connection.createStatement()) {
            // Turn the auto commit off
            connection.setAutoCommit(false);

            // Loop over every JSONObject inside of the JSONArray
            for(int i = 0; i < jsonArray.length(); i++) {
                Logger.getLogger().info("Processing json object " + (i+1) + " from file " + file.getName());
                statement.addBatch(insertJSONObjectIntoTable(jsonArray.getJSONObject(i), tableName, datetimeid, projectHashId));
            }

            // Execute the batch and receive the number of rows changed for every statement contained in the batch
            int[] rowChanages = statement.executeBatch();

            // Commit the batch of sql statements
            connection.commit();
            // Turn the auto commit back on
            connection.setAutoCommit(true);

        } catch (SQLException e) {
            Logger.getLogger().severe("Exception occurred while processing file " + file.getName() + ".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            return false;
        }
        return true;
    }

    /**
     * Executes an insert statement based on a specific JSONObject instance, a specific tableName and the
     * datatimeid of the object.
     *
     * @param object the JSONObject instance to insert
     * @param tableName the name of the table to insert the data into
     * @param datetimeid the datetimeid identifying the object
     *
     * @return true if successful, false if not
     *
     *
     * TODO: clean this up. This has to be possible in a much cleaner way
     */
    private String insertJSONObjectIntoTable(JSONObject object, String tableName, String datetimeid, String projectHashId) {
        // Create and initialize StringBuilder
        StringBuilder insertBuilder = new StringBuilder();
        insertBuilder.append("INSERT INTO stage.").append(tableName).append(" VALUES ");

        // start new values array here with "("
        insertBuilder.append("(");
        // in the first iteration, add datetimeid to the json
        insertBuilder.append(datetimeid).append(", ");

        // add the fileGroupId (the checksum of the zip file) to the json
        insertBuilder.append("\'").append(projectHashId).append("\'").append(", ");

        // Iterate over the keys in the json object
        Iterator<String> keys = object.keys();
        while(keys.hasNext()) {
            String key = keys.next();

            // Skip the timestamp field as datatimeid is the same and already present
            if(key.equals("Timestamp")) {
                // Timestamp was the last object, close the values parsing for this object
                if(!keys.hasNext()) {
                    //Strip ", " from the end of the insert builder
                    insertBuilder.deleteCharAt(insertBuilder.length() - 2);
                }
                continue;
            }

            // Extract the number values from the text containing "core" info
            if(tableName.equals("INSTANCECoreCounts") && key.equals("Text")) {
                String numberString = object.getString(key).replaceAll("[^-?0-9]+", " ");
                String[] numbers = numberString.trim().split(" ");

                insertBuilder.append(Integer.parseInt(numbers[0])).append(", ");
                insertBuilder.append(Integer.parseInt(numbers[1])).append(", ");
                insertBuilder.append(Integer.parseInt(numbers[2])).append(", ");
                insertBuilder.append(Integer.parseInt(numbers[3])).append(", ");
                insertBuilder.append(Integer.parseInt(numbers[4]));
                if(keys.hasNext()) {
                    insertBuilder.append(", ");
                }
                continue;
            }

            // Append the value to the insert query
            Object valueObject = object.get(key);
            // Some string values have to be handled differently
            if(valueObject instanceof String) {

                String valueString = (String) valueObject;

                // Special substitutions have to be done in order to insert scripts
                if(key.equals("script")) {
                    // Replace "'" operator to avoid parsing errors
                    valueString = valueString.replace("\'", "~");
                    // Insert "++" in front of every line of the script to avoid parsing errors
                    valueString = "++" + valueString;
                    valueString = valueString.replace("\r\n", "\r\n++");
                } else {
                    // Strip "'" operator to avoid parsing error
                    valueString = valueString.replace("\'", "");
                }

                // Every string has to start and end with the "'" operator
                // do not put "'" around NULL value for proper integer handling
                // if not done, the parser is receiving a string even tho he expects an integer
                if(!valueString.startsWith("\'") && !valueString.equals("NULL")) {
                    valueString = "\'" + valueString + "\'";
                }

                insertBuilder.append(valueString);
                // Substitute "TRUE" and "FALSE" with 0/1 bit
            } else if(valueObject instanceof Boolean) {
                if((Boolean) valueObject) {
                    insertBuilder.append(1);
                } else {
                    insertBuilder.append(0);
                }

            }  else {
                insertBuilder.append(valueObject);
            }

            //Prepare for next value if the current value isn't the last one
            if(keys.hasNext()) {
                insertBuilder.append(", ");
            }
        }
        return insertBuilder.append(");").toString();
    }

    /**
     * Creates a table based on a specific tableName and a specific file using the connection at the top of the class.
     *
     * @param tableName the specific table name
     * @param file the specific file
     */
    private boolean createTableFromFile(Connection connection, String tableName, File file) {
        try(Statement statement = connection.createStatement()) {
            StringBuilder queryBuilder = new StringBuilder();
            queryBuilder.append("CREATE TABLE stage.").append(tableName);
            queryBuilder.append(" (datetimeid BIGINT, ");
            queryBuilder.append("projectHashId NVARCHAR(1000), ");

            JSONArray jsonArray = JSONManager.getJSONArrayFromFile(file);

            if(jsonArray == null) {
                Logger.getLogger().warning("File is empty: " + file.getName());
                Logger.getLogger().warning("Skipping empty file: " + file.getName());
                return false;
            }

            if(jsonArray.length() > 0) {
                JSONObject object = jsonArray.getJSONObject(0);

                Iterator<String> keys = object.keys();
                while(keys.hasNext()) {
                    String key = keys.next();

                    // For the Core counts query, the information is returned as a string which is parsed later on.
                    // For every attribute withing the string, a new column has to be made.
                    if(tableName.equals("INSTANCECoreCounts") && key.equals("Text")) {
                        queryBuilder.append("Sockets ").append("INTEGER, ");
                        queryBuilder.append("CoresPerSocket ").append("INTEGER, ");
                        queryBuilder.append("LogicalProcessorsPerSocket ").append("INTEGER, ");
                        queryBuilder.append("TotalLogicalProcessors ").append("INTEGER, ");
                        queryBuilder.append("LicensedLogicalProcessors ").append("INTEGER");
                        if(keys.hasNext()) {
                            queryBuilder.append(", ");
                        } else {
                            queryBuilder.append(");");
                        }
                        continue;
                    }

                    // Skip timestamp filed as it is inserted as the first item manually
                    // at the top of the method
                    if(key.equals("Timestamp")) {
                        // if timestamp is the last field in the json, the queryBuilder string has to be closed manually
                        // as it is expecting more to come.
                        if(!keys.hasNext()) {
                            queryBuilder.replace(queryBuilder.lastIndexOf(","), queryBuilder.lastIndexOf(",") + 1, ");");
                        }
                        continue;
                    }

                    // Substitute key name
                    String subName = substituteKeyName(key);
                    queryBuilder.append(subName).append(" ");

                    Object obj = object.get(key);
                    if(obj instanceof Integer) {
                        queryBuilder.append("INTEGER");
                    } else if(obj instanceof Float) {
                        queryBuilder.append("FLOAT");
                    } else if(obj instanceof Date) {
                        queryBuilder.append("DATE");
                    } else {
                        if(N_VARCHAR_MAX_LIST.contains(subName.toLowerCase())) {
                            queryBuilder.append("NVARCHAR(MAX)");
                        } else {
                            queryBuilder.append("NVARCHAR(4000)");
                        }
                    }

                    if(keys.hasNext()) {
                        queryBuilder.append(", ");
                    } else {
                        queryBuilder.append(");");
                    }
                }
            } else {
                queryBuilder.replace(queryBuilder.lastIndexOf(","), queryBuilder.lastIndexOf(",") + 1, ");");
            }

            // Execute the query
            return statement.executeUpdate(queryBuilder.toString()) > 0;
        } catch (SQLException e) {
            Logger.getLogger().warning("Failed to create the " + tableName + " table!");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return false;
    }

    /**
     * Substitutes all illegal characters within a key name.
     *
     * @param key the key potentially containing illegal characters
     *
     * @return the substituted (illegal character free) key string
     */
    private String substituteKeyName(String key) {
        // replace "&" as is is considered an operator
        String substitute = key.replace("&", "And")
                // replace free spaces
                .replace(" ", "")
                //strip "("
                .replace("(", "")
                // strip ")"
                .replace(")", "")
                // replace "%" as it is considered an operator
                .replace("%", "InPercent")
                // replace "-" as it is considered an operator
                .replace("-", "")
                // replace "*" as it is considered an operator
                .replace("*", "")
                // replace "."
                .replace(".", "")
                // replace "/" as it is considered an operator
                .replace("/", "");

        // Make sure no tables get the name "DatabaseNameName", when the name "DatabaseName" is substituted
        if(substitute.equals("Database")) {
            substitute = substitute.replace("Database", "DatabaseName");
        }
        return substitute;
    }

    /**
     * Retrieves the name of the table based on a specific file (i.e., gets the check name that created the file
     * and strips the "-" from it.
     *
     * @param file the specific file
     *
     * @return the table name derived from the file
     */
    private String getTableNameFromFile(File file) {
        String[] splitFileName = file.getName().split("_");
        return splitFileName[splitFileName.length - 1].split("\\.")[0].replace("-", "");
    }

    /**
     * Retrieves the names of all tables of a database based on a specific check.
     *
     * @return the names of all tables as a set
     */
    private Set<String> retrieveTableNames(Connection connection) {
        Set<String> databaseNames = new HashSet<>();

        try {
            Statement statement = connection.createStatement();
            ResultSet results = statement.executeQuery(CheckLibrary.DATABASE_STAGE_TABLE_NAMES.getQuery());
            while(results.next()) {
                databaseNames.add(results.getString(1));
            }
        } catch (SQLException e) {
            Logger.getLogger().severe("Exception occurred while retrieving table names.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return databaseNames;
    }

    /**
     * Creates a specific database schema if the schema does not already exist.
     **
     * @return true, if the schema exists, false else
     */
    private boolean setupDBSchema(Connection connection) {
        try(Statement statement = connection.createStatement()) {
            // Check if schema is already present in database
            String query = CheckLibrary.SCHEMA_IN_DATABASE.getQuery() +  "\'" + UtilsJDBC.SCHEMA_STAGE + "\';";
            if(statement.executeQuery(query).isBeforeFirst()) {
                return true;
            }

            //Slack status message
            Slack.sendMessage("*Processor*: Schema *\"stage\"* is missing. Creating it now.");
            Logger.getLogger().warning("Creating missing \"" + UtilsJDBC.SCHEMA_STAGE + "\" schema.");

            // Create the schema
            return statement.executeUpdate(CheckLibrary.CREATE_SCHEMA.getQuery() + UtilsJDBC.SCHEMA_STAGE + ";") > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    /**
     * The main class.
     *
     * @param args the system arguments
     */
    public static void main(String[] args) {
        Git.initialize();
        new Processor().start();
    }
}
