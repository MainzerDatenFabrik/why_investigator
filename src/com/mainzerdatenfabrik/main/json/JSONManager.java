package com.mainzerdatenfabrik.main.json;

import com.mainzerdatenfabrik.main.logging.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Types;
import java.util.logging.Level;

/**
 * Implementation JSON converter to convert JDBC ResultSets to JSONArrays including a timestamp the conversion
 * happened.
 *
 * @author Aaron Priesterroth
 */
public class JSONManager {

    /**
     * Converts a specific SQL ResultSet into a JSONArray where each row inside of the ResultSet is represented by
     * a JSONObject inside of the array and returns it.
     *
     * @param resultSet - the specific SQL ResultSet
     *
     * @return - the created JSONArray
     */
    public static JSONArray convertResultSet(ResultSet resultSet, String timestamp) {
        Logger.getLogger().info("Converting ResultSet with timestamp=" + timestamp + ".");

        JSONArray jsonArray = new JSONArray();

        try {
            // Retrieve column names of the ResultSet
            ResultSetMetaData resultSetMD = resultSet.getMetaData();

            while(resultSet.next()) {
                JSONObject jsonObject = new JSONObject();

                for(int i = 1; i < resultSetMD.getColumnCount() + 1; i++) {
                    if(i == 1) {
                        jsonObject.put("Timestamp", timestamp);
                    }

                    // Currently observed column name
                    String columnName = resultSetMD.getColumnName(i);

                    // Retrieve value as object to check if it null
                    // This case has to be handled this way as jsons do not support (i.e., they do not show up)
                    // null objects
                    Object value = resultSet.getObject(columnName);
                    if(value == null) {
                        jsonObject.put(columnName, "NULL");
                    } else {
                        // Determine value type of currently observed column and store the value in the JSONObject
                        switch(resultSetMD.getColumnType(i)) {
                            case Types.ARRAY:  jsonObject.put(columnName, resultSet.getArray(columnName)); break;
                            case Types.BIGINT: jsonObject.put(columnName, resultSet.getInt(columnName)); break;
                            case Types.BOOLEAN: jsonObject.put(columnName, resultSet.getBoolean(columnName)); break;
                            case Types.BLOB:  jsonObject.put(columnName, resultSet.getBlob(columnName)); break;
                            case Types.DOUBLE: jsonObject.put(columnName, resultSet.getDouble(columnName)); break;
                            case Types.FLOAT: jsonObject.put(columnName, resultSet.getFloat(columnName)); break;
                            case Types.INTEGER: jsonObject.put(columnName, resultSet.getInt(columnName)); break;
                            case Types.NVARCHAR: jsonObject.put(columnName, resultSet.getNString(columnName)); break;
                            case Types.VARCHAR: jsonObject.put(columnName, resultSet.getString(columnName)); break;
                            case Types.TINYINT: jsonObject.put(columnName, resultSet.getInt(columnName)); break;
                            case Types.DATE:  jsonObject.put(columnName, resultSet.getDate(columnName)); break;
                            case Types.TIMESTAMP: jsonObject.put(columnName, resultSet.getTimestamp(columnName)); break;
                            //default: jsonObject.put(columnName, "NULL"); break;
                            default:
                                // compensate "0x" prefix of the owner_sid
                                // compensate "0x" prefix of ANY sid
                                if(columnName.equals("owner_sid") || columnName.equals("sid")) {
                                    jsonObject.put(columnName, resultSet.getString(columnName));
                                } else {
                                    jsonObject.put(columnName, value);
                                }
                                break;
                        }
                    }
                }
                jsonArray.put(jsonObject);
            }
        } catch (SQLException e) {
            Logger.getLogger().severe("Exception occurred while converting ResultSet to json.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            return null;
        }
        return jsonArray;
    }

    /**
     * Creates a JSONArray object based on a specific file.
     *
     * @param file the specific file to load the JSON String from
     *
     * @return the JSONArray object initialized with the JSON String retrieved from the specified file, null if the file
     * was empty
     *
     */
    public static JSONArray getJSONArrayFromFile(File file) {
        Logger.getLogger().info("Creating json array from file: " + file.getName() + ".");
        String jsonString = getJSONStringFromFile(file);
        if(!jsonString.equals("")) {
            return new JSONArray(getJSONStringFromFile(file));
        }
        Logger.getLogger().severe("Failed to create json array from file: " + file.getName() + ".");
        return null;
    }

    /**
     * Retrieves a JSON String from a specific file.
     *
     * @param file the specific file to load the JSON String from
     *
     * @return the JSON String retrieved from the specified file
     */
    public static String getJSONStringFromFile(File file) {
        Logger.getLogger().info("Retrieving json from file: " + file.getName() + ".");
        StringBuilder builder = new StringBuilder();

        try (BufferedReader reader = new BufferedReader(new FileReader(file.getPath()))) {
            String line;
            while((line = reader.readLine()) != null) {
                builder.append(line);
            }
        } catch (IOException e) {
            Logger.getLogger().severe("Failed to retrieve json string from file: " + file.getName() + ".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return  builder.toString();
    }

    /**
     * Retrieves a JSON String from a specific file path.
     *
     * @param path the specific file path to load the JSON String from
     *
     * @return the JSON String retrieved from the specific file path
     */
    public static String getJSONStringFromPath(String path) {
        return getJSONStringFromFile(new File(path));
    }

    /**
     * Retrieves the "datetimeid" from a jsonObject inside of a specific jsonArray.
     *
     * @param jsonArray the specific jsonArray
     *
     * @return the derived "datetimeid" string
     */
    public static String getDateTimeId(JSONArray jsonArray) {
        String dateTimeIdString = "";

        for(int i = 0; i < jsonArray.length(); i++) {
            JSONObject object = jsonArray.getJSONObject(i);
            if(object.keySet().contains("Timestamp")) {
                dateTimeIdString = object.getString("Timestamp");
                dateTimeIdString = dateTimeIdString.replace(" ", ""); // Strip " " from string
                dateTimeIdString = dateTimeIdString.replace("/", ""); // Strip "/" from string
                dateTimeIdString = dateTimeIdString.replace(":", ""); // Strip ":" from string
                dateTimeIdString = dateTimeIdString.substring(0, dateTimeIdString.length() - 2);
                break;
            }
        }
        return dateTimeIdString;
    }
}
