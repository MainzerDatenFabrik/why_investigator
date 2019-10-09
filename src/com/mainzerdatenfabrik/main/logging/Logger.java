package com.mainzerdatenfabrik.main.logging;

import java.io.IOException;
import java.util.logging.FileHandler;
import java.util.logging.Level;
import java.util.logging.SimpleFormatter;

public class Logger {

    // The logger itself
    private static java.util.logging.Logger logger;

    // The path to the file the Logger is logging into
    private static final String PATH_TO_LOG_FILE = "./logs/why_investigator.log";

    /**
     * Returns the global logger. Uses lazy initialization, meaning the logger is initialized just before the first time
     * it is used.
     *
     * @return the global logger
     */
    public static java.util.logging.Logger getLogger() {
        if(logger == null) {
            return initializeLogger();
        }
        return logger;
    }

    /**
     * Initializes the global logger and adds a FileHandler to it.
     */
    private static java.util.logging.Logger initializeLogger() {
        logger = java.util.logging.Logger.getLogger(Logger.class.getName());

        FileHandler fileHandler = null;
        try {
            fileHandler = new FileHandler(PATH_TO_LOG_FILE);
            fileHandler.setFormatter(new SimpleFormatter());
        } catch (IOException e) {
            e.printStackTrace();
        }
        if(fileHandler != null) {
            logger.setUseParentHandlers(false);
            logger.addHandler(fileHandler);
            logger.setLevel(Level.ALL);
        }
        return logger;
    }
}
