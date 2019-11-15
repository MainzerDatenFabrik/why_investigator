package com.mainzerdatenfabrik.main.logging.graylog;

import com.mainzerdatenfabrik.main.file.FileManager;
import com.mainzerdatenfabrik.main.logging.Logger;
import org.json.JSONObject;

import java.io.*;
import java.net.InetAddress;
import java.net.Socket;
import java.util.Iterator;
import java.util.logging.Level;

/**
 * Implementation of communication interface to Graylog tcp inputs.
 *
 * @author  Aaron Priesterroth
 * @version 0.1
 */
public class Graylog {

    // The ip of the graylog server
    private static  String ip_address = "";

    private static final int PORT_GENERAL = 9001;

    private static final int PORT_DATABASE = 9002;
    private static final int PORT_INSTANCE = 9003;
    private static final int PORT_USERS = 9004;

    private static final int PORT_SERVER_PROPERTIES = 9005;
    private static final int PORT_HARDWARE_INFO = 9006;
    private static final int PORT_SYS_ADMINS = 9007;
    private static final int PORT_CONNECTION_ERRORS = 9008;

    public static void initialize() {
        Logger.getLogger().config("Loading config for Graylog.");

        JSONObject graylogConfig = FileManager.getConfigObject("graylogConfig");

        ip_address = graylogConfig.getString("ip_address");

        Logger.getLogger().config("Finished loading config for Gaylog.");
    }

    /**
     * Sends a specific json object in string format to a specific graylog input node based on the name of the table
     * the json object (log file) was created for.
     *
     * @param jsonString the specific json object (i.e., log file) to send to graylog
     *
     * @return true, if the message was sent successfully, else false
     */
    public static boolean sendLog(String tableName, String jsonString) {

        // Specific sorting of log files
        if(tableName.equals("INSTANCEServerProperties")) {
            sendServerPropertiesLog(jsonString);
        }
        if(tableName.equals("INSTANCEHardwareInfo")) {
            sendHardwareInfoLog(jsonString);
        }
        if(tableName.equals("DatabaseConnectionErrors")) {
            sendConnectionErrorsLog(jsonString);
        }
        if(tableName.equals("USERSystemAdministratorInfo")) {
            sendSysAdminsLog(jsonString);
        }

        // General sorting of log files
        String tableNameLower = tableName.toLowerCase();

        if(tableNameLower.startsWith("database")) {
            return sendDatabaseLog(jsonString);
        } else if(tableNameLower.startsWith("instance")) {
            return sendInstanceLog(jsonString);
        } else if(tableNameLower.startsWith("user")) {
            return sendUsersLog(jsonString);
        } else {
            return send(PORT_GENERAL, jsonString, "1.1", "mainzerdatenfabrik.de", "Submit new log file.");
        }
    }

    /**
     * Sends a specific json object to the database graylog input
     *
     * @param jsonString the specific json object (i.e., log file) to send
     *
     * @return true, if the object was sent successfully, else false
     */
    private static boolean sendDatabaseLog(String jsonString) {
        return send(PORT_DATABASE, jsonString, "1.1", "mainzerdatenfabrik.de", "Submit new database log file.");
    }

    /**
     * Sends a specific json object to the instance graylog input
     *
     * @param jsonString the specific json object (i.e., log file) to send
     *
     * @return true, if the object was sent successfully, else false
     */
    private static boolean sendInstanceLog(String jsonString) {
        return send(PORT_INSTANCE, jsonString, "1.1", "mainzerdatenfabrik.de", "Submit new instance log file.");
    }

    /**
     * Sends a specific json object to the users graylog input
     *
     * @param jsonString the specific json object (i.e., log file) to send
     *
     * @return true, if the object was sent successfully, else false
     */
    private static boolean sendUsersLog(String jsonString) {
        return send(PORT_USERS, jsonString, "1.1", "mainzerdatenfabrik.de", "Submit new users log file.");
    }

    /**
     * Sends a specific json object to the server properties graylog input
     *
     * @param jsonString the specific json object (i.e., log file) to send
     *
     * @return true, if the object was sent successfully, else false
     */
    private static boolean sendServerPropertiesLog(String jsonString) {
        return send(PORT_SERVER_PROPERTIES, jsonString, "1.1", "mainzerdatenfabrik.de", "Submit new server properties log file.");
    }

    /**
     * Sends a specific json object to the hardware info graylog input
     *
     * @param jsonString the specific json object (i.e., log file) to send
     *
     * @return true, if the object was sent successfully, else false
     */
    private static boolean sendHardwareInfoLog(String jsonString) {
        return send(PORT_HARDWARE_INFO, jsonString, "1.1", "mainzerdatenfabrik.de", "Submit new hardware info log file.");
    }

    /**
     * Sends a specific json object to the sys admin graylog input
     *
     * @param jsonString the specific json object (i.e., log file) to send
     *
     * @return true, if the object was sent successfully, else false
     */
    private static boolean sendSysAdminsLog(String jsonString) {
        return send(PORT_SYS_ADMINS, jsonString, "1.1", "mainzerdatenfabrik.de", "Submit new sys admins log file.");
    }

    /**
     * Sends a specific json object to the connection error graylog input
     *
     * @param jsonString the specific json object (i.e., log file) to send
     *
     * @return true, if the object was sent successfully, else false
     */
    private static boolean sendConnectionErrorsLog(String jsonString) {
        return send(PORT_CONNECTION_ERRORS, jsonString, "1.1", "mainzerdatenfabrik.de", "Submit new connection error log file.");
    }

    /**
     * Sends a specific json object in string format to the Graylog server specified by {@code ip_address} based on
     * a specific version string, a host name and a short message (description of the message) to create a gelf
     * object from the specified json object string.
     *
     * @param port         the port to send the message on
     * @param jsonString   the specified json object string
     * @param version      the version of the gelf protocol
     * @param host         the host name (i.e., who sent the message)
     * @param shortMessage the short description of the message (log file)
     *
     * @return true, if the message was sent successfully, else false
     */
    private static boolean send(int port, String jsonString, String version, String host, String shortMessage) {
        try(Socket socket = new Socket(InetAddress.getByName(ip_address), port);
            OutputStream outputStream = new DataOutputStream(socket.getOutputStream())) {

            PrintWriter writer = new PrintWriter(outputStream);
            writer.println(createGELF(jsonString, version, host, shortMessage));
            writer.flush();

            return true;
        } catch (IOException e) {
            Logger.getLogger().severe("Unable to establish a tcp connection to " + ip_address + ":" + port);
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return false;
    }

    /**
     * Converts a json object string into a valid gelf string by adding the required "version/host/short_message"
     * fields. Additionally, all whitespaces in the keys of the original json object are replaced with underscores and
     * all bracket literals are stripped.
     *
     * @param jsonString    the original json object representing the log file
     * @param version       the version of the gelf file
     * @param host          the host for the gelf file (i.e., who sent the message)
     * @param shortMessage short description of the gelf file
     *
     * @return the created gelf file string
     */
    private static String createGELF(String jsonString, String version, String host, String shortMessage) {
        JSONObject gelf = new JSONObject();
        JSONObject json = new JSONObject(jsonString);
        Iterator<String> keys = json.keys();

        while(keys.hasNext()) {
            String key = keys.next();
            String keyModified = "_" + key.replace(" ", "_").replace("(", "").replace(")", "");
            gelf.put(keyModified, json.get(key));
        }

        gelf.put("version", version);
        gelf.put("host", host);
        gelf.put("short_message", shortMessage);

        return gelf.toString();
    }
}
