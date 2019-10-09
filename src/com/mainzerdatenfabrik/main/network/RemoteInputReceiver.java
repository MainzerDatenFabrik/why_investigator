package com.mainzerdatenfabrik.main.network;

import com.mainzerdatenfabrik.main.control.ControlPanel;
import com.mainzerdatenfabrik.main.logging.Logger;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.logging.Level;

public class RemoteInputReceiver {

    // The parent ControlPanel the RemoteInputReceiver is listening for
    private final ControlPanel parent;

    // The port on which the salve should listen for new commands.
    private final int port;

    // Indicates if the receiver is/should running/run
    private boolean receiverRunning = false;

    // Indicates if the receiver is active (i.e., handling a new connection) or not
    private boolean receiverActive = false;

    // The receiver, waiting for new connections to open
    private Thread receiver;

    /**
     * The Constructor.
     */
    public RemoteInputReceiver(ControlPanel parent, int port) {
        this.parent = parent;
        this.port = port;

        startReceiver();
    }

    /**
     * Handles the message coming from a newly connected socket and returns a response based on the
     * action described by the message.
     * If a problem occurred while processing the command, the message "Oops, something went wrong!" is returned.
     *
     * @param message the message retrieved from the newly connected socket, indicating what action to execute
     */
    private String handle(String message) {
        Logger.getLogger().info("Handling message: " + message + ".");

        String response = "Oops, something went wrong!";

        switch (message.toLowerCase()) {
            case "e!":
            case "1":
            case "start sqlworker":
            case "2":
            case "start filewatcher":
            case "3":
            case "start processor":
            case "5":
            case "stop sqlworker":
            case "6":
            case "stop filewatcher":
            case "7":
            case "stop processor":
            case "info-flag":
                response = parent.processRemoteInput(message);
                break;
            case "termination-flag":
                response = "Bye!";
                break;
        }
        Logger.getLogger().info("Responding with: " + response + ".");
        return response;
    }

    /**
     * Creates a new thread and initializes it with the "setupReceiver" method and starts the thread.
     */
    private void startReceiver() {
        receiverRunning = true;
        receiver = new Thread(setupReceiver());
        receiver.start();
    }

    /**
     * Creates a new runnable for the receiver to execute. All the receiver does is listen on a specific port
     * and pass on any incoming connection to the "handleIncomingConnection" method.
     * Since the receiver thread is stuck in an infinite loop with blocking class, the thread has to interrupted to
     * exit.
     *
     * @return the runnable created for the receiver thread
     */
    private Runnable setupReceiver() {
        return () -> {
            try(ServerSocket server = new ServerSocket(port)) {
                while(isReceiverRunning()) {
                    Socket connection = server.accept();
                    receiverActive = true;
                    handleIncomingConnection(connection);
                    receiverActive = false;
                }
            } catch (IOException e) {
                Logger.getLogger().severe("Exception occurred listening for incoming connections.");
                Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            }
            Logger.getLogger().info("RemoteInputReceiver EXIT.");
        };
    }

    /**
     * Stops the receiver by interrupting it. This method BLOCKS until the receiver is stopped, which is only done
     * if the receiver is in a safe state. The Receiver is in a safe state whenever it is not processing a newly
     * discovered connection.
     */
    public void stopReceiver() {
        Logger.getLogger().info("Stopping the RemoteInputReceiver.");

        receiverRunning = false;

        if(!isReceiverActive()) {
            try {
                // Create a new connection for the receiver to break out of the blocking
                // server.accept() call
                Socket socket = new Socket("localhost", port);

                DataInputStream dis = null;
                DataOutputStream dos = null;
                try {
                    dos = new DataOutputStream(new BufferedOutputStream(socket.getOutputStream()));
                    // Send a message that indicates nothing has to be done
                    dos.writeUTF("termination-flag");
                    dos.flush();
                    dis = new DataInputStream(new BufferedInputStream(socket.getInputStream()));
                    String response = dis.readUTF();
                    Logger.getLogger().info("Retrieved response: " + response + ".");
                } catch (IOException e) {
                    Logger.getLogger().severe("Exception occurred while stopping the RemoteInputReceiver.");
                    Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
                } finally {
                    try {
                        if(dis != null) dis.close();
                        if(dos != null) dos.close();
                        socket.close();
                    } catch (IOException e) {
                        Logger.getLogger().severe("Exception occurred while closing streams.");
                        Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
                    }
                }
            } catch (IOException e) {
                Logger.getLogger().severe("Exception occurred while opening connection to RemoteInputReceiver.");
                Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            }
        }
        Logger.getLogger().info("Finished stopping the RemoteInputReceiver.");
    }

    /**
     *
     * @return true, if the receiver is active (i.e., processing a newly discovered connection), else false
     */
    public boolean isReceiverActive() {
        return receiverActive;
    }

    /**
     *
     * @return true, if the receiver is/should running/run, else false
     */
    public boolean isReceiverRunning() {
        return receiverRunning;
    }

    /**
     * Handles a newly connected socket.
     *
     * @param connection the newly connected socket
     */
    private void handleIncomingConnection(Socket connection) {
        Logger.getLogger().info("Opening new connection to: " + connection.toString() + ".");

        DataInputStream dis = null;
        DataOutputStream dos = null;
        try {
            // The input stream to receiver the message from the newly connected socket
            dis = new DataInputStream(new BufferedInputStream(connection.getInputStream()));

            // Process the receiver message (i.e., the command)
            String response = handle(dis.readUTF());

            // The output stream to put the response for the received message from the newly connected socket
            dos = new DataOutputStream(new BufferedOutputStream(connection.getOutputStream()));

            // Send the response to the newly connected socket
            dos.writeUTF(response);
            dos.flush();
        } catch (IOException e) {
            Logger.getLogger().severe("Exception occurred using connection: " + connection.toString() + ".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        } finally {
            try {
                if(dis != null) dis.close();
                if(dos != null) dos.close();
            } catch (IOException e) {
                Logger.getLogger().severe("Exception occurred while closing the streams.");
                Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            }
        }
        Logger.getLogger().info("Finished handling incoming connection: " + connection.toString() + ".");
    }
}
