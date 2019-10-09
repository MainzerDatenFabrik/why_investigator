package com.mainzerdatenfabrik.main.shell;

import com.mainzerdatenfabrik.main.logging.Logger;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

public class StreamGobbler extends Thread {

    private final InputStream inputStream;
    private final String type;

    public StreamGobbler(InputStream inputStream, String type) {
        this.inputStream = inputStream;
        this.type = type;
    }

    @Override
    public void run() {
        try (BufferedReader br = new BufferedReader(new InputStreamReader(inputStream))) {
            String line;
            while ((line = br.readLine()) != null) {
                Logger.getLogger().info(line);
            }
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }
    }
}