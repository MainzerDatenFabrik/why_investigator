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
    private static  String ip_address;

    private static boolean enabled;

    private static final int PORT_GENERAL = 9001;

    private static final int PORT_DATABASE = 9002;
    private static final int PORT_INSTANCE = 9003;
    private static final int PORT_USERS = 9004;

    private static final int PORT_SERVER_PROPERTIES = 9005;
    private static final int PORT_HARDWARE_INFO = 9006;
    private static final int PORT_SYS_ADMINS = 9007;
    private static final int PORT_CONNECTION_ERRORS = 9008;

    // Performance
    private static final int PORT_CPU_UTILIZATION = 9009;
    private static final int PORT_CPU_UTILIZATION_HISTORY = 9010;
    private static final int PORT_DRIVE_LEVEL_LATENCY = 9011;
    private static final int PORT_IO_LATENCY = 9012;
    private static final int PORT_PROCESS_MEMORY = 9013;
    private static final int PORT_SYSTEM_MEMORY = 9014;
    private static final int PORT_TOP_WORKER_TIME_QUERIES = 9015;
    private static final int PORT_VOLUME_INFO = 9016;
    private static final int PORT_CPU_USAGE_BY_DATABASE = 9017;
    private static final int PORT_IO_USAGE_BY_DATABASE = 9018;

    private static final int PORT_FACT_OBJECT_MODIFICATION = 9019;
    private static final int PORT_FACT_SCAN_TAB = 9020;
    private static final int PORT_FACT_SERVER_PROPERTIES = 9021;
    private static final int PORT_FACT_USER_BASE_INFO = 9022;
    private static final int PORT_FACT_USER_BASE_INFO_SYS_ADMINS = 9023;

    public static void initialize() {
        Logger.getLogger().config("Loading config for Graylog.");

        JSONObject graylogConfig = FileManager.getConfigObject("graylogConfig");

        ip_address = graylogConfig.getString("ip_address");
        enabled = graylogConfig.getBoolean("enabled");

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
        switch(tableName) {
            case "INSTANCEServerProperties": send(PORT_SERVER_PROPERTIES, jsonString); break;
            case "INSTANCEHardwareInfo": send(PORT_HARDWARE_INFO, jsonString); break;
            case "INSTANCECPUUtilization": send(PORT_CPU_UTILIZATION, jsonString); break;
            case "INSTANCECPUUtilizationHistory": send(PORT_CPU_UTILIZATION_HISTORY, jsonString); break;
            case "INSTANCEDriveLevelLatency": send(PORT_DRIVE_LEVEL_LATENCY, jsonString); break;
            case "INSTANCEIOLatency": send(PORT_IO_LATENCY, jsonString); break;
            case "INSTANCEProcessMemory": send(PORT_PROCESS_MEMORY, jsonString); break;
            case "INSTANCESystemMemory": send(PORT_SYSTEM_MEMORY, jsonString); break;
            case "INSTANCETopWorkerTimeQueries": send(PORT_TOP_WORKER_TIME_QUERIES, jsonString); break;
            case "INSTANCEVolumeInfo": send(PORT_VOLUME_INFO, jsonString); break;
            case "INSTANCECPUUsageByDatabase": send(PORT_CPU_USAGE_BY_DATABASE, jsonString); break;
            case "INSTANCEIOUsageByDatabase": send(PORT_IO_USAGE_BY_DATABASE, jsonString); break;
            case "USERSystemAdministratorInfo": send(PORT_SYS_ADMINS, jsonString); break;
            case "DatabaseConnectionErrors": send(PORT_CONNECTION_ERRORS, jsonString); break;
            case "fact.ObjectModification": return send(PORT_FACT_OBJECT_MODIFICATION, jsonString);
            case "fact.scantab": return send(PORT_FACT_SCAN_TAB, jsonString);
            case "fact.ServerProperties": return send(PORT_FACT_SERVER_PROPERTIES, jsonString);
            case "fact.UserBaseInfo": return send(PORT_FACT_USER_BASE_INFO, jsonString);
            case "fact.UserBaseInfoSysadmin": return send(PORT_FACT_USER_BASE_INFO_SYS_ADMINS, jsonString);
        }

        // General sorting of log files
        String tableNameLower = tableName.toLowerCase();

        int port = (tableNameLower.startsWith("database") ? PORT_DATABASE :
                   (tableNameLower.startsWith("instance")) ? PORT_INSTANCE :
                   (tableNameLower.startsWith("user")) ? PORT_USERS : PORT_GENERAL);

        return send(port, jsonString);
    }

    /**
     * Wrapper for the send method. Sends a specific json object in string format to the Graylog server specified
     * by {@code ip_address} based on specific host to create a geld object from the specified json object string.
     *
     * @param port       the port to send the message on
     * @param jsonString the specified json object string
     *
     * @return true, if the message was sent successfully, else false
     */
    public static boolean send(int port, String jsonString) {
        return send(port, jsonString, "1.0", "why_investigator", "Submit new log file.");
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
            String keyModified = "_" + key.replace(" ", "_")
                    .replace("(", "")
                    .replace(")", "")
                    .replace("/", "");
            gelf.put(keyModified, json.get(key));
        }

        gelf.put("version", version);
        gelf.put("host", host);
        gelf.put("short_message", shortMessage);

        return gelf.toString();
    }

    /**
     * Indicates whether or not to send messages to the Graylog inputs or not.
     *
     * @return true, if messages should be sent, else false
     */
    public static boolean isEnabled() {
        return enabled;
    }
}
