package com.mainzerdatenfabrik.main.network;

import com.mainzerdatenfabrik.main.logging.Logger;

import java.io.*;
import java.net.Socket;
import java.util.logging.Level;

public class RemoteController {

    /**
     * Send a specific message to a socket connection based on a specific ip address and a specific port.
     *
     * @param message the message to send to the socket
     * @param ip the ip address of the socket to send the message to
     * @param port the port the socket to send the message to is listening on
     *
     * @return the response string from the connected socket, null if an exception was thrown
     */
    public String sendTo(String message, String ip, int port) {
        Logger.getLogger().info("Sending message " + message + " to <" + ip + ":" + port + ">.");

        Socket connection;
        try {
            Logger.getLogger().info("Trying to connect to: <" + ip + ":" + port + ">.");
            connection = new Socket(ip, port);
        } catch (IOException e) {
            Logger.getLogger().severe("Failed to connect to: <" + ip + ":" + port + ">.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            return null;
        }

        DataInputStream dis = null;
        DataOutputStream dos = null;
        String response = null;
        try {
            Logger.getLogger().info("Sending message: " + message + ".");

            // The output stream to send messages to the connected socket
            dos = new DataOutputStream(new BufferedOutputStream(connection.getOutputStream()));

            // Send the message to the connected socket
            dos.writeUTF(message);
            dos.flush();

            // The input stream to receive the response from the connected socket
            dis = new DataInputStream(new BufferedInputStream(connection.getInputStream()));

            // Receive the response to the previously sent command
            response = dis.readUTF();
        } catch (IOException e) {
            Logger.getLogger().severe("Failed to send the message.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        } finally {
            try {
                if(dis != null) dis.close();
                if(dos != null) dos.close();
                connection.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        Logger.getLogger().info("Returning received response: " + response + ".");
        return response;
    }
}
