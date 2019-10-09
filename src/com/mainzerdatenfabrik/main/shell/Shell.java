package com.mainzerdatenfabrik.main.shell;

import com.mainzerdatenfabrik.main.logging.Logger;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.logging.Level;

public class Shell {


    /**
     * Used to execute a command via "cmd/terminal".
     *
     * @param directory the directory the command in executed in
     * @param commands one to many commands to be executed
     */
    public static int executeCommand(File directory, String... commands) {
        ProcessBuilder pb = new ProcessBuilder()
                .command(commands)
                .directory(directory);

        int exit = 0;

        try {
            Process p = pb.start();

            StreamGobbler errorGobbler = new StreamGobbler(p.getErrorStream(), "WARNING");
            errorGobbler.start();
            StreamGobbler outputGobbler = new StreamGobbler(p.getInputStream(), "OUTPUT");
            outputGobbler.start();

            exit = p.waitFor();
            errorGobbler.join();
            outputGobbler.join();

            if(exit != 0) {
                Logger.getLogger().warning("Shell.executeCommand returned: " + exit + ".");
            }
        } catch (IOException | InterruptedException e) {
            Logger.getLogger().severe("Exception occurred while executing command.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return exit;
    }

    /**
     *  Executes a command on the "cmd/terminal" and returns the output of the command in string format.
     *
     * @param commands the array of command to execute
     *
     * @return the output of the command in string format.
     */
    public static String executeInfoCommand(String... commands) {
        return  executeInfoCommand(null, commands);
    }

    /**
     *  Executes a command on the "cmd/terminal" and returns the output of the command in string format.
     *
     * @param directory the directory to execute the command in. If null, the command is executed in no specific
     *                  directory.
     * @param commands the array of command to execute
     *
     * @return the output of the command in string format.
     */
    public static String executeInfoCommand(File directory, String... commands) {
        ProcessBuilder pb = new ProcessBuilder().command(commands);
        if(directory != null) {
            pb.directory(directory);
        }

        StringBuilder output = new StringBuilder();

        try {
            Process p = pb.start();

            try (BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream(), "CP850"))) {
                String line;
                while ((line = br.readLine()) != null) {
                    output.append(line).append("\n");
                }
            } catch (IOException ioe) {
                Logger.getLogger().severe("Exception occurred while reading console output.");
                Logger.getLogger().log(Level.SEVERE, ioe.getMessage(), ioe);
            }
        } catch (IOException e) {
            Logger.getLogger().severe("Exception occurred while executing info command.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return output.toString();
    }

    /**
     * Converts the string retrieved from an "icacls" command into a cleaner format (i.e., strips all of the redundant
     * white spaces from the string).
     *
     * @param rawString the string to convert
     *
     * @return the converted string
     */
    public static String formatPermissionString(String rawString) {
        if(rawString == null) {
            Logger.getLogger().warning("Can't format null string.");
            return null;
        }
        String string = rawString.substring(rawString.indexOf(" "), rawString.lastIndexOf(")")+1);
        string = string.replaceAll(" {2,}", "\n");
        return string;
    }
}
