package com.mainzerdatenfabrik.main.library;

import com.mainzerdatenfabrik.main.logging.Logger;
import com.mainzerdatenfabrik.main.utils.Utils;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.logging.Level;

/**
 * Implementation of a library of checks of three different types ("user", "instance", "database") using the "Singleton
 * Pattern". The instance of the class is created lazily, meaning that it is created the first time the "getInstance"
 * method is called.
 */
public class CheckLibrary {

    public static final Check CREATE_PROTOCOL_TABLE =
            new Check(
                    "CUSTOM Create Protocol Table",
                    "10.50.2500.0",
                    "CREATE TABLE [stage].[FileProtocols]([datetimeid] [BIGINT] NOT NULL, " +
                            "[fqdn] [VARCHAR](4000) NOT NULL, [fileName] [VARCHAR](4000) NOT NULL, " +
                            "[fileHash] [VARCHAR](4000) NOT NULL, [fileGitPath] [VARCHAR](4000) NOT NULL," +
                            " [projectHashId] [VARCHAR](4000) NOT NULL);",
                    Check.Type.CUSTOM);

    /**
     * Custom check query to retrieve the server version string.
     */
    public static final Check SERVER_PRODUCT_VERSION =
            new Check(
                    "CUSTOM Server Product Version",
                    "10.50.2500.0",
                    convertQuery("SELECT SERVERPROPERTY('ProductVersion') AS [ProductVersion];"),
                    Check.Type.CUSTOM);

    /**
     * Custom check query to retrieve all database names from a specific instance. The databases with "database_id" of
     * 1, 2, 3 or 4 are ignored as they are all system databases.
     */
    public static final Check SERVER_DATABASES_OVERVIEW =
            new Check(
                    "CUSTOM Server Databases Overview",
                    "10.50.2500.0",
                    "DECLARE @Domain NVARCHAR(100)\n" +
                            "EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\\CurrentControlSet\\services\\Tcpip\\Parameters', N'Domain',@Domain OUTPUT\n" +
                            "SELECT  Cast(SERVERPROPERTY('MachineName') as nvarchar) + '.' + @Domain AS FQDN, name FROM sys.databases WHERE database_id NOT IN (1,2,3,4);",
                    Check.Type.CUSTOM);

    /**
     * Custom check query to retrieve all table names from a specific database. The format in which the table names
     * are returned contain their schema as well (e.g., "schemaName.tableName").
     */
    public static final Check DATABASE_STAGE_TABLE_NAMES =
            new Check(
                    "CUSTOM Database Table Names",
                    "10.50.2500.0",
                    "SELECT name AS SchemaTable FROM sys.tables WHERE " +
                            "'['+SCHEMA_NAME(schema_id)+'].['+name+']' LIKE '%STAGE%'",
                    Check.Type.CUSTOM);

    /**
     * Custom check query to retrieve all table names from a specific database. The format in which the table names
     * are returned contain their schema as well (e.g., "schemaName.tableName").
     */
    public static final Check DATABASE_DIM_TABLE_NAMES =
            new Check(
                    "CUSTOM Database Table Names",
                    "10.50.2500.0",
                    "SELECT name AS SchemaTable FROM sys.tables WHERE " +
                            "'['+SCHEMA_NAME(schema_id)+'].['+name+']' LIKE '%DIM%'",
                    Check.Type.CUSTOM);

    /**
     * Custom check query to check if a file with a specific "fileHash" is already contained in the
     * "stage.FileProtocols" table.
     *
     * CAREFUL: This query is not complete and needs to be completed by appending a value for "fileHash" before
     * using it.
     */
    public static final Check PROTOCOL_TABLE_CONTAINS_FILE =
            new Check(
                    "CUSTOM Protocol Table Contains File",
                    "10.50.2500.0",
                    "SELECT * FROM stage.FileProtocols WHERE fileHash = ",
                    Check.Type.CUSTOM);

    /**
     * Custom check query to check if a specific schema identified by its name is in an instance.
     *
     * CAREFUL: This query is not complete and needs to be completed by appending a value for "name" before using it.
     */
    public static final Check SCHEMA_IN_DATABASE =
            new Check(
                    "CUSTOM Stage Schema In Database",
                    "10.50.2500.0",
                    "SELECT * FROM sys.schemas WHERE name = ",
                    Check.Type.CUSTOM);

    /**
     * Custom check query to create a schema on an instance.
     *
     * CAREFUL: This query is not complete and needs to be competed by appending a name for the schema to create before
     * using it.
     */
    public static final Check CREATE_SCHEMA =
            new Check(
                    "CUSTOM Create Stage Schema",
                    "10.50.2500.0",
                    "CREATE SCHEMA ",
                    Check.Type.CUSTOM);

    // The only instance of the class
    private static CheckLibrary instance;

    // The array of "instance" check queries
    private Check[] instanceChecks;
    // The array of "database" check queries
    private Check[] databaseChecks;
    // The array of "user" check queries
    private Check[] userChecks;

    /**
     * The Constructor
     */
    private CheckLibrary() {
        load();
    }

    /**
     *
     * @return all check queries of type "instance"
     */
    public Check[] getInstanceChecks() {
        return instanceChecks;
    }

    /**
     *
     * @return all check queries of type "database"
     */
    public Check[] getDatabaseChecks() {
        return databaseChecks;
    }

    /**
     *
     * @return all check queries of type "user"
     */
    public Check[] getUserChecks() {
        return userChecks;
    }

    /**
     *
     * @return the singleton instance of the CheckLibrary (if the instance is not initialized yet, it is created)
     */
    public static CheckLibrary getInstance() {
        if(instance == null) {
            instance = new CheckLibrary();
        }
        return instance;
    }

    /**
     * Loads check queries from a file specified by filepath organizes them into their
     * corresponding array list.
     */
    private void load() {
        Logger.getLogger().info("Loading CheckLibrary.");

        ArrayList<Check> instanceChecks = new ArrayList<>();
        ArrayList<Check> databaseChecks = new ArrayList<>();
        ArrayList<Check> userChecks = new ArrayList<>();

        try(BufferedReader reader = new BufferedReader(new FileReader(Utils.PATH_TO_LIBRARY_FILE))) {

            String line, name = "", minCompatibleVersion = "";
            Check.Type type = null;

            StringBuilder query = new StringBuilder();

            boolean convert = false;

            int readerOffset = 0;

            while((line = reader.readLine()) != null) {
                // Empty line end the current check reading
                if(line.equals("")) {
                    Logger.getLogger().info("Parsed check: " + name + ".");

                    ArrayList<Check> group;

                    switch (type) {
                        case INSTANCE: group = instanceChecks; break;
                        case DATABASE: group = databaseChecks; break;
                        case USER: group = userChecks; break;
                        default:
                            Logger.getLogger().severe("Unable to find the group for check query: " + name + " with type: " + type + ".");
                            return;
                    }

                    final String oName = name; // must be final for lambda expression
                    final Check check = group.stream().filter(o -> o.getName().equals(oName)).findFirst().orElse(null);

                    if(check == null) {
                        Check c = new Check(name, type);
                        c.addQuery(minCompatibleVersion, convert ? convertQuery(query.toString()) : query.toString());
                        group.add(c);
                    } else {
                        check.addQuery(minCompatibleVersion, convert ? convertQuery(query.toString()) : query.toString());
                    }

                    readerOffset = 0;
                    query = new StringBuilder();

                    continue;
                }

                // If the line starts with a "#", it is a comment and can be ignored
                if(!line.startsWith("#")) {
                    switch (readerOffset) {
                        case 0:
                            name = line;
                            readerOffset++;
                            break;
                        case 1:
                            minCompatibleVersion = line;
                            readerOffset++;
                            break;
                        case 2:
                            convert = line.equals("true");
                            readerOffset++;
                            break;
                        case 3:
                            type = line.equals("instance") ? Check.Type.INSTANCE : line.equals("database") ?
                                    Check.Type.DATABASE : Check.Type.USER;
                            readerOffset++;
                            break;
                        case 4:
                            query.append(line).append("\n");
                            break;
                    }
                }
            }
        } catch (IOException e) {
            Logger.getLogger().severe("Exception occurred while parsing the CheckLibrary.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }

        this.instanceChecks = instanceChecks.toArray(new Check[0]);
        this.databaseChecks = databaseChecks.toArray(new Check[0]);
        this.userChecks = userChecks.toArray(new Check[0]);
        Logger.getLogger().info("Finished loading the CheckLibrary.");
    }

    /**
     * Converts a query sentence from "SQL_Variant" format into "VARCHAR" format line by line.
     *
     * For the conversion to work properly, the original query sentence should be in a format where every operator
     * is capitalized (e.g., SELECT, AS, ...) and the sentence should end with a ";".
     *
     * @param query - the query sentence
     *
     * @return - the converted query sentence
     */
    public static String convertQuery(String query) {
        // Split text into array of lines
        String[] lines = query.split("\\r?\\n");

        // Initialize StringBuilder for the declaration parts
        StringBuilder declareString = new StringBuilder();

        // Substrings a complete declare part is made of
        // declareSub3 is an alternative to declareSub4 and vice versa
        final String declareSub1 = "DECLARE @";
        final String declareSub2 = " AS SQL_VARIANT\n";
        final String declareSub3 = "SET @";
        final String declareSub4 = "=(";
        final String declareSub5 = "=(SELECT ";
        final String declareSub6 = ")\n";

        // Initialize StringBuilder for the select part
        StringBuilder selectString = new StringBuilder().append("SELECT");

        // Substrings the select part is made of
        final String castSub1 = " CAST (@";
        final String castSub2 = " AS VARCHAR(max))";

        // The name base for the declarations -> var + iteration => e.g., var0, var1, ...
        final String variableName = "var";

        for(int i = 0; i < lines.length; i++) {
            String line = lines[i];

            if(!line.equals("")) {
                // The index of the substring "AS" within the line
                int asIndex = line.indexOf("AS");
                // Substring of everything before the "asIndex" without the last blank space
                String queryPart = line.substring(0, asIndex - 1);
                // Substring of everything from the "asIndex" to the end of the line without "," or ";"
                String namePart = line.substring(asIndex)
                        .replace(",", "")
                        .replace(";", "");

                // Append "declare" for the current line
                // E.e., DECLARE @var0 AS SQL_VARIANT
                declareString.append(declareSub1).append(variableName).append(i).append(declareSub2);

                // Append "set" for the current line
                // E.g., SET @var0=(SELECT SERVERPROPERTY('MachineName'))
                declareString.append(declareSub3).append(variableName).append(i)
                        .append(line.startsWith("SELECT") ? declareSub4 : declareSub5).append(queryPart)
                        .append(declareSub6);

                // Append "select" for the current line
                // E.g., CAST (@name0 AS VARCHAR(max)) AS [MachineName] + "," or ";"
                selectString.append(castSub1).append(variableName).append(i).append(castSub2).append(namePart)
                        .append(i == lines.length - 1 ? ";" : ",");
            }
        }
        return declareString.toString() + selectString.toString();
    }
}


























