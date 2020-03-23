package com.mainzerdatenfabrik.main.worker;

import com.mainzerdatenfabrik.main.file.FileManager;
import com.mainzerdatenfabrik.main.library.Check;
import com.mainzerdatenfabrik.main.library.CheckLibrary;
import com.mainzerdatenfabrik.main.logging.slack.Slack;
import com.mainzerdatenfabrik.main.utils.UtilsJDBC;
import com.mainzerdatenfabrik.main.logging.Logger;
import com.mainzerdatenfabrik.main.utils.Utils;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Date;
import java.util.logging.Level;

public class WorkerTask implements Runnable {

    private static final int DATABASE_NAME_INDEX = 2;

    private final SQLWorker parent;

    private final String hostName;

    private final int port;
    private final int frequency;

    private final boolean user;
    private final boolean instance;
    private final boolean database;

    private String serverVersion;

    // The username and password for the sql server the worker is connecting to. If the username and password are
    // empty, ad authentication is used.
    private final String sqlUsername;
    private final String sqlPassword;

    /**
     * The constructor.
     *
     * @param parent the SQLWorkerOld instance that created the task for a worker thread
     * @param hostName the name of the host to connect to
     * @param port the port to connect on
     * @param frequency the frequency in which the checks are executed in minutes
     * @param user indicates if user checks should be executed
     * @param instance indicates if instance checks should be executed
     * @param database indicates if database checks should be executed
     */
    public WorkerTask(SQLWorker parent, String sqlUsername, String sqlPassword, String hostName, int port, int frequency,
                      boolean user, boolean instance, boolean database) {
        this.parent = parent;
        this.sqlUsername = sqlUsername;
        this.sqlPassword = sqlPassword;
        this.hostName = hostName;
        this.port = port;
        this.frequency = frequency;
        this.user = user;
        this.instance = instance;
        this.database = database;
    }

    /**
     * The overwritten run method. Contains the main logic of the class.
     */
    @Override
    public void run() {
        serverVersion = retrieveServerVersion(UtilsJDBC.establishConnection(hostName, port, sqlUsername, sqlPassword));
        Logger.getLogger().info("Retrieved server version string: " + serverVersion + ".");

        while(parent.isChildrenRunning()) {
            // Set the "active" flag of the worker to true, indicating
            // that it is not safe to terminate the WorkerThread instance at the moment
            parent.updateWorkerStatus(Thread.currentThread().getName(), true);

            // Create a new folder for this specific worker to write his logs into
            if(FileManager.workerDirExists(Thread.currentThread().getName())) {
                FileManager.cleanWorkerDirectory(Thread.currentThread().getName(), false);
            }

            try {
                // The timestamp for the current iteration
                String timestamp = Utils.DATE_TIME_FORMAT.format(new Date());

                if(user) {
                    Logger.getLogger().info("Performing user library checks.");
                    performChecks(CheckLibrary.getInstance().getUserChecks(), timestamp);
                }
                if(instance) {
                    Logger.getLogger().info("Performing instance library checks!");
                    performChecks(CheckLibrary.getInstance().getInstanceChecks(), timestamp);
                }
                if(database) {
                    Logger.getLogger().info("Performing database library checks!");
                    performDatabaseChecks(CheckLibrary.getInstance().getDatabaseChecks(), timestamp);
                }

                /**
                 * After refactoring the projectHashId, it is now created based on the configuration of the worker
                 * creating the batch and is appended to the filename of the batch.
                 */
                String projectHashIdStr = hostName + port + sqlUsername;
                if(user) projectHashIdStr += "user";
                if(instance) projectHashIdStr += "instance";
                if(database) projectHashIdStr += "database";

                String projectHashId = FileManager.calculateChecksum(projectHashIdStr);

                FileManager.processWorkersDirectory(Thread.currentThread().getName(), "SQLWorker", hostName, timestamp, projectHashId);

                // Set the "active" flag of the worker to false, indicating
                // that it is safe to interrupt and terminate the worker at the moment
                parent.updateWorkerStatus(Thread.currentThread().getName(), false);
                if(parent.isChildrenRunning()) {
                    Logger.getLogger().info("Sleeping for " + frequency + " minutes.");
                    Thread.sleep(Utils.MS_PER_MIN * frequency);
                }
            } catch (InterruptedException e) {
                Logger.getLogger().info("Worker " + Thread.currentThread().getName() + " interrupted.");
            }
        }
        Logger.getLogger().info("Worker " + Thread.currentThread().getName() + " EXIT.");
    }

    /**
     * Performs checks based on a specific array of checks and the timestamp of the current iteration. The results of
     * every check are then stored as a file in json format.
     *
     * @param checks the array of checks to perform
     * @param timestamp the timestamp of the current iteration of the worker
     */
    public void performChecks(Check[] checks, String timestamp) {
        Connection connection;
        if((connection = UtilsJDBC.establishConnection(hostName, port, sqlUsername, sqlPassword)) == null) {
            FileManager.writeConnectionErrorLog(Thread.currentThread().getName(), timestamp, hostName, port,
                    UtilsJDBC.NO_SPECIFIC_DATABASE);
            return;
        }

        for(Check check : checks) {
            String query = check.getQuery(serverVersion);

            if(query != null) {
                Logger.getLogger().info(Thread.currentThread().getName() + " executing check: " + check.getName() + ".");
                try {
                    Statement statement = connection.createStatement();
                    processQueryResults(statement.executeQuery(query), check, timestamp,
                            UtilsJDBC.NO_SPECIFIC_DATABASE);
                    statement.close();
                } catch (SQLException e) {
                    Logger.getLogger().warning("SQL Exception occurred while performing checks.");
                    Logger.getLogger().warning("Query: " + query);
                    Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
                    Slack.sendMessage("*SQLWorker*: SQL exception occurred: *" + e.getMessage() + "*.");
                }
            } else {
                Logger.getLogger().warning("Check " + check.getName() + " is not compatible with version " + serverVersion + "!");
            }
        }

        try {
            connection.close();
        } catch (SQLException e) {
            Logger.getLogger().info("Exception occurred while performing check.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
    }

    /**
     * Performs database checks based on a specific array of checks and the timestamp of the current iteration. The
     * results of every check are then stored as a file in json format.
     * The special thing with database checks is, that the connection has to be based on a database name, not only the
     * host and port.
     *
     * @param checks the array of checks to perform
     * @param timestamp the timestamp of the current iteration of the worker
     */
    public void performDatabaseChecks(Check[] checks, String timestamp) {
        String[] databaseNames = retrieveDatabaseNames(timestamp);
        if(databaseNames == null) {
            Logger.getLogger().severe("Unable to retrieve databasenames for: " + hostName + ":" + port);
            return;
        }

        Connection connection = null;
        for(String databaseName : databaseNames) {
            // Properly close previous connection
            if(connection != null) {
                try {
                    connection.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            Logger.getLogger().info("Opening connection to " + hostName + ":" + port + "/" + databaseName + ".");
            if((connection = UtilsJDBC.establishConnection(hostName, port, databaseName, sqlUsername, sqlPassword)) == null) {
                FileManager.writeConnectionErrorLog(Thread.currentThread().getName(), timestamp, hostName, port,
                        databaseName);
                return;
            }

            String query = "";
            try {
                Statement statement = connection.createStatement();
                if(statement == null) {
                    Logger.getLogger().severe("Unable to create statement for " + Thread.currentThread().getName() + ".");
                    return;
                }

                for(Check check : checks) {
                    query = check.getQuery(serverVersion);

                    if(query != null) {
                        Logger.getLogger().info("Executing check: " + check.getName() + ".");
                        processQueryResults(statement.executeQuery(query), check, timestamp, databaseName);
                    } else {
                        Logger.getLogger().warning("Check " + check.getName() + " is not compatible with version " + serverVersion + ".");
                    }
                }

                statement.close();
            } catch (SQLException e) {
                Logger.getLogger().warning("Exception occurred while performing database check.");
                Logger.getLogger().warning("Query: " + query);
                Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            }
        }
        try {
            if(connection != null) connection.close();
        } catch (SQLException e) {
            Logger.getLogger().severe("Exception occurred while closing connection.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
    }

    /**
     * Used to retrieve the names of all databases of the specific instance the worker is working for.
     *
     * @param timestamp the timestamp of the current iteration of the worker
     *
     * @return the array of databases names retrieved from the instance
     */
    public String[] retrieveDatabaseNames(String timestamp) {

        ArrayList<String> databaseNames = new ArrayList<>();

        Connection connection = UtilsJDBC.establishConnection(hostName, port, sqlUsername, sqlPassword);
        if(connection == null) {
            return null;
        }

        try {
            Statement statement = connection.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                    ResultSet.CONCUR_READ_ONLY);
            ResultSet results = statement.executeQuery(CheckLibrary.SERVER_DATABASES_OVERVIEW.getQuery());

            // Add all names of databases from the query to the list
            while(results.next()) {
                databaseNames.add(results.getString(DATABASE_NAME_INDEX));
            }

            // Reset the cursor of the results
            results.beforeFirst();
            // Save the results
            processQueryResults(results, CheckLibrary.SERVER_DATABASES_OVERVIEW, timestamp, UtilsJDBC.NO_SPECIFIC_DATABASE);
        } catch (SQLException e) {
            Logger.getLogger().severe("Exception occurred while retrieving database names.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return databaseNames.toArray(new String[0]);
    }

    /**
     * Used to save the results of a check query to file in json format.
     *
     * @param results the results of the performed check
     * @param check the performed check itself
     * @param timestamp the timestamp of the current iteration of the worker
     * @param databaseName the name of the database the connection is based on. If specific database is used, the
     *                     flag "Utils.NO_SPECIFIC_DATABASE" must be used.
     */
    public void processQueryResults(ResultSet results, Check check, String timestamp, String databaseName) {
        try {
            // this returns false if the cursor is not before the first record or if there are no rows in the ResultSet.
            // i.e., detects if the result set is empty
            if(results.isBeforeFirst()) {
                Logger.getLogger().info("Saving results of check: " + check.getName() + " to file.");
                FileManager.writeLog(Thread.currentThread().getName(), results, timestamp, hostName,
                        databaseName, check);
            } else {
                Logger.getLogger().info("Skip saving empty results from check: " + check.getName() + ".");
            }
        } catch (SQLException e) {
            Logger.getLogger().severe("Exception occurred while processing query results.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
    }

    /**
     * Retrieves the SQL Server Version based on a specific connection using one of the CUSTOM queries
     * of the CheckLibrary and returns it.
     *
     * @return - the retrieved SQL Server Version represented by a string, null if unable to establish a connection or
     * an exception occurs.
     */
    private String retrieveServerVersion(Connection connection) {
        try(Statement statement = connection.createStatement()) {
            ResultSet results = statement.executeQuery(CheckLibrary.SERVER_PRODUCT_VERSION.getQuery());
            if(results.next()) {
                return results.getString(1);
            }
        } catch (SQLException e) {
            Logger.getLogger().severe("Exception occurred while retrieving server version.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        } catch(Exception e) {

        }
        return null;
    }
}
