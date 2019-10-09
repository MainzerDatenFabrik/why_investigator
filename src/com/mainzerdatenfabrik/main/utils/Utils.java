package com.mainzerdatenfabrik.main.utils;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

public class Utils {

    /**
     * Path to the config file.
     *
     * THIS HAS TO BE SWITCHED BETWEEN
     *
     *          "./res/config_aaron.txt"
     * AND
     *          "./res/config_benedikt.txt"
     *
     */
    public static final String PATH_TO_CONFIG_FILE = "./res/config_aaron.txt";

    /**
     * Exit codes:
     *      - 1 = Failed to establish a connection
     *      - 2 =
     *      - 3 =
     */
    public static final int EXIT_CODE_FAILED_CONNECTION = 1;

    // Simple DataFormat to easily extract date and time from the current datetime
    public static final DateFormat DATE_TIME_FORMAT = new SimpleDateFormat("yyy/MM/dd HH:mm:ss");

    // The simple date format for converting the lastModified time
    public static final SimpleDateFormat LAST_MODIFIED_DATE_TIME_FORMAT = new SimpleDateFormat("yyyyMMddHHmmss");

    // Path to the libraries file.
    public static final String PATH_TO_LIBRARY_FILE = "./res/libraries.txt";

    public static final int DEFAULT_PORT = 1433;

    // How many milli seconds are in a second
    public static final int MS_PER_MIN = 60000;

    // Indicates weather or not the program is running on windows os
    private static final String OPERATING_SYSTEM_NAME = System.getProperty("os.name");

    // The default size of batches created
    public static final int BATCH_SIZE_DEFAULT = 1000;

    /**
     * Indicates weather or not the operating system is windows
     *
     * @return true, if the os is windows, else false
     */
    public static boolean isWindowsOS() {
        return OPERATING_SYSTEM_NAME.startsWith("Windows");
    }

    /**
     * Creates a "datetimeid" from a specific timestamp. The "datetimeid" is a identifier based on time and is used
     * in multiple occasions, such as filenames and table keys.
     *
     * Format: timestamp="02/05/2019 17:18:00" -> datetimeid="02052019171819"
     *
     * @param timestamp the timestamp to constructed the "datetimeid" from
     *
     * @return the datetimeid
     */
    public static String getDatetimeId(String timestamp) {
        return timestamp
                .replace("/", "")
                .replace(":", "")
                .replace(" ", "");
    }

    /**
     * Creates a "datetimeid" for the current date/time. The "datatimeid" is an identifier based on time and i sued in
     * multiple occasions, such as filenames and table keys.
     *
     * @return the datetimeid for the current date/time (now)
     */
    public static String getDatetimeId() {
        return getDatetimeId(DATE_TIME_FORMAT.format(new Date()));
    }

    /**
     * Replaces all "umlauts" (i.e., ü, ä, ö -> ue, ae, oe) and return the new string.
     *
     * @param input the string to replace the umlauts from.
     *
     * @return the string with all lower/upper case umlauts replaced
     */
    public static String replaceUmlauts(String input) {
        // replace lower case "Umlaute"
        String output = input.replace("ü", "ue")
                .replace("ö", "oe")
                .replace("ä", "ae")
                .replace("ß", "ss");

        // replace all capital "Umlaute"
        output = output.replace("Ü", "Ue")
                .replace("Ö", "Oe")
                .replace("Ä", "Ae");

        return output;
    }

    /**
     * Creates and returns a random string of a specific length consisting of characters from a specific domain.
     *
     * @param length the length of the random string to generate
     * @param domain the domain of the string (i.e., the characters to chose random characters from)
     *
     * @return the random string of specified length
     */
    public static String randomString(int length, String domain) {
        StringBuilder builder = new StringBuilder();
        while(length-- > 0) {
            builder.append(domain.charAt((int) (Math.random()*domain.length())));
        }
        return builder.toString();
    }

    /**
     * Creates and returns a random alpha numeric string of specific length.
     *
     * @param length the length of the random string to generate
     *
     * @return the random alpha numeric string of specified length
     */
    public static String randomAlphaNumericString(int length) {
        return randomString(length, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
    }
}
