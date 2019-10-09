package com.mainzerdatenfabrik.main.control;

import com.mainzerdatenfabrik.main.file.FileManager;
import com.mainzerdatenfabrik.main.git.Git;
import com.mainzerdatenfabrik.main.logging.slack.Slack;
import com.mainzerdatenfabrik.main.network.RemoteController;
import com.mainzerdatenfabrik.main.network.RemoteInputReceiver;
import com.mainzerdatenfabrik.main.processor.Processor;
import com.mainzerdatenfabrik.main.utils.UtilsCP;
import com.mainzerdatenfabrik.main.logging.Logger;
import com.mainzerdatenfabrik.main.watcher.FileWatcher;
import com.mainzerdatenfabrik.main.worker.SQLWorker;
import org.json.JSONObject;

import java.util.*;

/**
 *
 */
public class ControlPanel {

    // The queries to retrieve information for the Synchronizer class
    private static final String QUERY_DATABASES = "SELECT name FROM sys.databases WHERE database_id NOT IN (1,2,3,4);";
    private static final String QUERY_VIEWS = "SELECT SCHEMA_NAME(schema_id) AS SchemaName, name AS ViewName FROM sys.views;";
    private static final String QUERY_PROCEDURES = "SELECT SCHEMA_NAME(schema_id) AS SchemaName, name AS ProcedureName FROM sys.procedures;";

    // Indicates if the ControlPanel instance should continue running (i.e., continue showing the "main screen")
    private boolean exit = false;

    // Indicates if the SQLWorker instance is running
    private boolean workerRunning = false;
    // Indicates if the Processor instance is running
    private boolean processorRunning = false;
    // Indicates if the FileWatcher instance is running
    private boolean watcherRunning = false;
    // Indicates if the Synchronizer instance is running
    private boolean synchronizerRunning = false;

    // The Scanner instance listening on the default System.in (i.e., the console) for user input
    private Scanner scanner = new Scanner(System.in);

    // The SQLWorker instance
    private SQLWorker worker;
    // The FileWatcher instance
    private FileWatcher watcher;
    // The Processor instance
    private Processor processor;

    // The RemoteInputReceiver instance listening for incoming remote commands
    private RemoteInputReceiver remoteInputReceiver;
    // The RemoteController instance to send remote commands to another instance
    private RemoteController remoteController;

    // This boolean flag indicates if the ControlPanel instance is privileged to access the "RemoteControl" panel
    private boolean isMaster;
    // The port specified in the config file. This is the port on which the RemoteInputReceiver is listening
    // for incoming remote commands
    private int port;

    // The thread responsible for handling and listening for user input
    private final Thread inputThread;

    //Timer for the hourly callback for slack logging
    private Timer timer;
    private long delay;
    private long period;

    // The user and pw for the synchronizer module
    private String syncUser;
    private String syncPass;

    /**
     * The constructor.
     */
    public ControlPanel() {

        loadConfig();

        //Slack status message
        Slack.sendMessage("The *WhyInvestigator* has just been *started*. Frequent status information will be given in this channel while the application is running.");

        // Slack status message (hourly callback)
        TimerTask repeatedTask = new TimerTask() {
            @Override
            public void run() {
                Slack.sendMessage("*Hourly status update*:");
                Slack.sendMessage("- SQLWorker:       " + (workerRunning ? "*online*" : "*offline*"));
                Slack.sendMessage("- FileWatcher:      " + (watcherRunning ? "*online*" : "*offline*"));
                Slack.sendMessage("- Processor:          " + (processorRunning ? "*online*" : "*offline*"));
            }
        };
        timer = new Timer("Timer");
        timer.scheduleAtFixedRate(repeatedTask, delay, period);

        if(isMaster) {
            Logger.getLogger().info("Instance is master, creating the RemoteController.");
            remoteController = new RemoteController();
        }
        Logger.getLogger().info("Creating the RemoteInputReceiver.");
        remoteInputReceiver = new RemoteInputReceiver(this, port);

        Logger.getLogger().info("Creating and starting the inputThread to handle user input.");
        // Create a new daemon thread to handle the user input. This is important for the remote call of
        // "exit", because the Scanner blocks on the console waiting for input. Since this is a "daemon" the thread
        // is automatically closed on exit by the JVM without blocking the program from termination.
        inputThread = new Thread(() -> {
            showWelcomeScreen();
            showMainScreen(true);
        });
        inputThread.setDaemon(true);
        inputThread.start();
    }

    /**
     * Print the "main screen" to the console. Retrieves the status of both programs (worker and processor) as well
     * as some status info (e.g., ONLINE - idle).
     */
    private void showMainScreen(boolean localInput) {
        while(!exit) {
            Logger.getLogger().info("Showing the \"main screen\". Local user input expected: " + localInput + ".");

            String name = "SQLWorker";
            String status = "Status 1";
            UtilsCP.m05 = getModuleLabel(name, watcherRunning);
            //
            name = "FileWatcher";
            status = "Status 2";
            UtilsCP.m07 = getModuleLabel(name, watcherRunning);
            //UtilsCP.m08 = getModuleStatusLabel(name, status);

            name = "Processor";
            status = "Status 3";
            UtilsCP.m09 = getModuleLabel(name, synchronizerRunning);
            //UtilsCP.m12 = getModuleStatusLabel(name, status);

            // print main screen
            System.out.println(
                    UtilsCP.m01 + UtilsCP.m02 +
                            UtilsCP.m03 + // label 1
                            UtilsCP.m04 + // status label
                            UtilsCP.m05 + UtilsCP.m06 +
                            UtilsCP.m07 + // label 2
                            UtilsCP.m08 + // status label
                            UtilsCP.m09 + UtilsCP.m10 +
                            UtilsCP.m11 + // label 3
                            UtilsCP.m12 + // status label
                            UtilsCP.m13 + UtilsCP.m14 +
                            UtilsCP.m15 + UtilsCP.m16 +
                            UtilsCP.m17 + UtilsCP.m18 +
                            UtilsCP.m19 + UtilsCP.m20 +
                            UtilsCP.m21 + UtilsCP.m22 +
                            UtilsCP.m23);

            // call handleUserInput with parameter null only if local user input is expected after showing the main
            // screen. The "null" parameter indicates that the input has to come from the console (which is
            // local user input)
            if(localInput) {
                Logger.getLogger().info("Getting user input for the \"main screen\".");
                handleUserInput(null);
            } else {
                Logger.getLogger().info("Leaving \"main screen\" loop without getting user input.");
                break;
            }
        }
    }

    /**
     * Listens for user input from the console and acts out the desired action specified by the user.
     *
     * @param input the user input to handle. If the input is null, the input is expected to come from the console.
     *              If it is not null, it is input from a remote remoteController control.
     */
    private String handleUserInput(String input) {
        // get user input if no remote input is available
        if(input == null) {
            Logger.getLogger().info("Waiting for user input.");
            input = scanner.nextLine();
            Logger.getLogger().info("Retrieved user input: " + input + ".");
        }

        String response = "";

        // process user input
        switch(input.toLowerCase()) {
            case "e":
            case "exit":
                Logger.getLogger().info("Handling \"exit\" command.");
                if(showExitConfirmScreen()) {
                    Logger.getLogger().info("Exit confirmed. Terminating the program.");
                    exit();
                }
                break;
            case "e!": // force/remote quit
                Logger.getLogger().info("Handling \"force exit\" command. Terminating the program.");
                response = "Terminating program.";
                exit();
                break;
            case "h":
            case "help":
                Logger.getLogger().info("Handling \"help\" command.");
                showHelpScreen(); break;
            case "a":
            case "about":
                Logger.getLogger().info("Handling \"about\" command.");
                showAboutScreen(); break;
            case "1":
            case "start sqlworker":
                Logger.getLogger().info("Handling \"start sqlworker\" command.");
                if(!workerRunning) {
                    workerRunning = true;
                    (worker = new SQLWorker()).start();
                    response = "Started the SQLWorker.";

                    //Slack status message
                    Slack.sendMessage("The *SQLWorker* module has just been *started*!");

                } else {
                    response = "SQLWorker is already running.";
                    showResponseScreen(response); // Todo: this is not the proper screen for this!
                }
                Logger.getLogger().info(response);
                break;
            case "2":
            case "start filewatcher":
                Logger.getLogger().info("Handling the  \"start filewatcher\" command.");
                if(!watcherRunning) {
                    watcherRunning = true;
                    (watcher = new FileWatcher()).start();
                    response = "Started the FileWatcher.";

                    //Slack status message
                    Slack.sendMessage("The* FileWatcher* module has just been *started*!");
                } else {
                    response = "The FileWatcher is already running.";
                    showResponseScreen(response); // Todo: this is not the proper screen for this!
                }
                Logger.getLogger().info(response);
                break;
            case "3":
            case "start processor":
                Logger.getLogger().info("Handling \"start processor\" command.");
                if(!processorRunning) {
                    processorRunning = true;
                    (processor = new Processor()).start();
                    response = "Started the Processor.";

                    //Slack status message
                    Slack.sendMessage("The *Processor* module has just been *started*!");
                } else {
                    response = "Processor is already running.";
                    showResponseScreen(response); // Todo: this is not the proper screen for this!
                }
                Logger.getLogger().info(response);
                break;
            case "4":
            case "open remotecontroller":
                Logger.getLogger().info("Handling \"open remotecontroller\" command.");
                if(isMaster) {
                    //Slack status message
                    Slack.sendMessage("The *RemoteController* interface has just been *opened*!");

                    response = "Opened RemoteController.";
                    showRemoteConfigScreen();
                } else {
                    response = "Not privileged to open RemoteController.";
                    showAccessDeniedScreen();
                }
                Logger.getLogger().info(response);
                break;
            case "5":
            case "stop sqlworker":
                Logger.getLogger().info("Handling \"stop sqlworker\" command.");
                if(workerRunning) {
                    workerRunning = false;
                    worker.terminate();
                    response = "Stopped the SQLWorker";

                    //Slack status message
                    Slack.sendMessage("The *SQLWorker* module has just been *stopped*!");
                } else {
                    response = "SQLWorker is already stopped.";
                    showResponseScreen(response); // Todo: this is not the proper screen for this!
                }
                Logger.getLogger().info(response);
                break;
            case "6":
            case "stop filewatcher":
                Logger.getLogger().info("Handling \"stop filewatcher\" command.");
                if(watcherRunning) {
                    watcherRunning = false;
                    watcher.terminate();
                    response = "Stopped the FileWatcher.";

                    //Slack status message
                    Slack.sendMessage("The *FileWatcher* module has just been *stopped*!");
                } else {
                    response = "FileWatcher is already stopped.";
                    showResponseScreen(response); // Todo: this is not the proper screen for this!
                }
                Logger.getLogger().info(response);
                break;
            case "7":
            case "stop processor":
                Logger.getLogger().info("Handling \"stop processor\" command.");
                if(processorRunning) {
                    processorRunning = false;
                    processor.terminate();
                    response = "Stopped the processor.";

                    //Slack status message
                    Slack.sendMessage("The *Processor* module has just been *stopped*!");
                } else {
                    response = "Processor is already stopped.";
                    showResponseScreen(response); // Todo: this is not the proper screen for this!
                }
                Logger.getLogger().info(response);
                break;
            case "info-flag":
                Logger.getLogger().info("Handling \"info-flag\" command.");
                response = createInfoString();
                Logger.getLogger().info("Returning info: " + response);
                break;
            default:
                response = "Undefined command: " + input;
                Logger.getLogger().warning(response);
                break;
        }
        return response;
    }

    /**
     * Creates a string based on the current status of the instance. I.e., puts into a string if worker, watcher and
     * processor are on-/offline and if the instance has "master" privileges.
     *
     * @return the created string described above.
     */
    private String createInfoString() {
        return "workerRunning:" + workerRunning + ";" +
                "watcherRunning:" + watcherRunning + ";" +
                "processorRunning:" + processorRunning + ";" +
                "isMaster:" + isMaster + ";";
    }

    /**
     * Creates the "module label" string for a specific module name based on a current status of the module
     * (i.e., ONLINE or OFFLINE).
     *
     * @param name the name of the module the label is for
     * @param status the current status of the module
     * @param prefix the prefix to append at the beginning of the line
     * @param appendix the appendix to append at the end of the line
     *
     * @return the string constructed from the provided information
     */
    private String getModuleLabel(String name, boolean status, String prefix, String appendix) {
        String statusPlain = status ? "ONLINE" : "OFFLINE";
        String statusColored = status ? UtilsCP.paintString(UtilsCP.ANSI_GREEN, statusPlain) :
                UtilsCP.paintString(UtilsCP.ANSI_RED, statusPlain);
        return prefix + name + ":" + " ".repeat(
                UtilsCP.MAX_MODULE_LABEL_LENGTH - (name.length()+1 + statusPlain.length())) + statusColored + appendix;
    }

    /**
     * Creates the "module label" string for a specific module name based on a current status of the module
     * (i.e., ONLINE or OFFLINE).
     *
     * @param name the name of the module the label is for
     * @param status the current status of the module
     *
     * @return the string constructed from the provided information, null if the name of the module is unknown
     */
    private String getModuleLabel(String name, boolean status) {
        switch (name) {
            case "SQLWorker": return getModuleLabel(name, status, UtilsCP.m05_1, UtilsCP.m05_2);
            case "FileWatcher": return getModuleLabel(name, status, UtilsCP.m07_1, UtilsCP.m07_2);
            case "Processor": return getModuleLabel(name, status, UtilsCP.m09_1, UtilsCP.m09_2);
            default:
                Logger.getLogger().severe("Can't construct module label for unknown module: " + name);
                return null;
        }
    }

    /**
     * Creates the "module status label" string for a specific module name based on a current status message of the
     * module.
     *
     * @param status the current status message of the module
     * @param prefix the prefix to append at the beginning of the line
     * @param appendix the appendix to append at the end of the line
     *
     * @return
     */
    private String getModuleStatusLabel(String status, String prefix, String appendix) {
        return prefix + status + " ".repeat(UtilsCP.MAX_MODULE_STATUS_LABEL_LENGTH - status.length()) + appendix;
    }

    /**
     * Creates the "module status label" string for a specific module name based on a current status message of
     * the module.
     *
     * @param name the name of the module the label is for
     * @param status the status message of the module
     *
     * @return the string constructed from the provided information, null if the name of the module is unknown
     */
    /*
    private String getModuleStatusLabel(String name, String status) {
        switch (name) {
            case "SQLWorker": return getModuleStatusLabel(status, UtilsCP.m04_1, UtilsCP.m04_2);
            case "FileWatcher": return getModuleStatusLabel(status, UtilsCP.m08_1, UtilsCP.m08_2);
            case "Processor": return getModuleStatusLabel(status, UtilsCP.m12_1, UtilsCP.m12_2);
            default:
                Logger.getLogger().severe("Can't construct module status label for unknown module: " + name);
                return null;
        }
    }
     */

    //------------------------------------------------------------------------------------------------------------------
    // Remote Controller
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Prints the "remote config screen" to the console asking the local user to input an "ip address" and a "port"
     * to connect to. After both parameters are entered by the user, the "info-flag" command is executed on remote
     * to retrieve the current status. All information is then passed to the "showRemoteControlScreen".
     */
    private void showRemoteConfigScreen() {
        Logger.getLogger().info("Showing \"remote config screen\".");

        String content =
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                             REMOTE IPv4 ADDRESS                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                    Please enter the remote IPv4 address to                   │\n" +
                        "│                                  connect to:                                 │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n";
        String ipAddress = showInputScreen(content);
        Logger.getLogger().config("RemoteControl - Retrieved ip address: " + ipAddress);

        content =
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                   REMOTE PORT                                │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                        Please enter the port to connect to:                  │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n";
        int port = Integer.parseInt(showInputScreen(content));
        Logger.getLogger().config("RemoteControl - Retrieved port: " + port);

        Logger.getLogger().info("Trying to remotely control <" + ipAddress + ":" + port + ">.");
        showRemoteControlScreen(ipAddress, port, remoteController.sendTo("info-flag", ipAddress, port));
    }

    /**
     * Prints the "remote control screen" to the console waiting for user input. The Screen contains information
     * about the current status of the remote connection specified by remoteInfo.
     * The user can select one of multiple commands from the list of commands and the command will be remotely
     * executed on the connection specified by ip and port.
     *
     * @param ip         the ip address of the remote connection (i.e., the address of who to connect to)
     * @param port       the port of the remote connection
     * @param remoteInfo the current status info of remote
     */
    private void showRemoteControlScreen(String ip, int port, String remoteInfo) {

        boolean returnToMain = false;

        while(!returnToMain) {
            Logger.getLogger().info("Showing the \"remote control screen\" for <" + ip + ":" + port + ">.");

            boolean workerRunning = false;
            boolean watcherRunning = false;
            boolean processorRunning = false;
            boolean isMaster = false;

            String[] splitInfo = remoteInfo.split(";");
            for(String string : splitInfo) {
                String[] splitLine = string.split(":");
                switch (splitLine[0]) {
                    case "workerRunning": workerRunning = Boolean.parseBoolean(splitLine[1]); break;
                    case "watcherRunning": watcherRunning = Boolean.parseBoolean(splitLine[1]); break;
                    case "processorRunning": processorRunning = Boolean.parseBoolean(splitLine[1]); break;
                    case "isMaster": isMaster = Boolean.parseBoolean(splitLine[1]); break;
                }
            }

            String name = "SQLWorker";
            UtilsCP.r03 = getModuleLabel(name, workerRunning, UtilsCP.r03_1, UtilsCP.r03_2);
            name = "FileWatcher";
            UtilsCP.r05 = getModuleLabel(name, watcherRunning, UtilsCP.r05_1, UtilsCP.r05_2);
            name = "Processor";
            UtilsCP.r07 = getModuleLabel(name, processorRunning, UtilsCP.r07_1, UtilsCP.r07_2);

            String label = "Connected to:";
            UtilsCP.r10 = UtilsCP.r10_1 + label + " ".repeat(UtilsCP.MAX_MODULE_LABEL_LENGTH - label.length()) + UtilsCP.r10_2;
            label = " - master:  " + isMaster;
            UtilsCP.r11 = UtilsCP.r11_1 + label + " ".repeat(UtilsCP.MAX_MODULE_LABEL_LENGTH - label.length()) + UtilsCP.r11_2;
            label = " - ip:      " + ip;
            UtilsCP.r12 = UtilsCP.r12_1 + label + " ".repeat(UtilsCP.MAX_MODULE_LABEL_LENGTH - label.length()) + UtilsCP.r12_2;
            label = " - port:    " + port;
            UtilsCP.r13 = UtilsCP.r13_1 + label + " ".repeat(UtilsCP.MAX_MODULE_LABEL_LENGTH - label.length()) + UtilsCP.r13_2;

            System.out.println(
                    UtilsCP.r01 + UtilsCP.r02 +
                            UtilsCP.r03 + // label 1
                            UtilsCP.r04 + // status label
                            UtilsCP.r05 + UtilsCP.r06 +
                            UtilsCP.r07 + // label 2
                            UtilsCP.r08 + // status label
                            UtilsCP.r09 + UtilsCP.r10 +
                            UtilsCP.r11 + // label 3
                            UtilsCP.r12 + // status label
                            UtilsCP.r13 + UtilsCP.r14 +
                            UtilsCP.r15 + UtilsCP.r16 +
                            UtilsCP.r17 + UtilsCP.r18 +
                            UtilsCP.r19 + UtilsCP.r20 +
                            UtilsCP.r21 + UtilsCP.r22 +
                            UtilsCP.r23);

            Logger.getLogger().info("Getting user input for the \"remote control screen\".");
            returnToMain = handleUserRemoteInput(ip, port);

            if(!returnToMain) {
                remoteInfo = remoteController.sendTo("info-flag", ip, port);
            }
        }
    }

    /**
     * Listens for user input from the console and acts out the desired action specified by the user on remote.
     */
    private boolean handleUserRemoteInput(String ip, int port) {

        Logger.getLogger().info("Waiting for user input.");
        String line = scanner.nextLine();
        Logger.getLogger().info("Retrieved user input: " + line);

        String response = null;

        switch (line.toLowerCase()) {
            case "r":
            case "return":
                Logger.getLogger().info("Handling \"return\" command. Returning to the \"main screen\".");
                return true;
            case "h":
            case "help":
                Logger.getLogger().info("Handling \"remote help\" command.");
                showRemoteHelpScreen(); break;
            case "4":
            case "terminate program":
                Logger.getLogger().info("Handling \"terminate program\" command.");
                response = remoteController.sendTo("e!", ip, port); break;
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
                Logger.getLogger().info("Handling \"" + line + "\" command.");
                response = remoteController.sendTo(line, ip, port);
                Logger.getLogger().info("Responding with: " + response);
                break;
            default:
                Logger.getLogger().warning("Unknown command: " + line + ".");
        }

        if(response != null) {
            Logger.getLogger().info("Showing \"response screen\" for response: " + response + ".");
            showResponseScreen(response);
        }
        return false;
    }

    /**
     * Handles the input coming from a remote user retrieved by the RemoteInputReceiver listener. After handling the input, the
     * main screen is updated.
     *
     * @param input the input coming from the remote user
     */
    public String processRemoteInput(String input) {
        Logger.getLogger().info("Processing remote input: " + input + ".");

        String response = handleUserInput(input);
        showMainScreen(false);

        Logger.getLogger().info("Returning response \"" + response + "\" from handled remote input.");
        return response;
    }
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Prints the "access denied" screen to the console.
     */
    private void showAccessDeniedScreen() {
        Logger.getLogger().info("Showing \"access denied screen\".");

        String content =
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                      You are not privileged to access the                    │\n" +
                        "│                                 RemoteControl.                               │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n";

        showInfoScreen(content);
    }

    /**
     * Prints the response retrieved from executing a remote command to the console packed into an "info screen".
     *
     * @param response the response returned from executing a remote command
     */
    private void showResponseScreen(String response) {
        Logger.getLogger().info("Showing \"response screen\".");

        int maxLength = 78 - response.length();
        String lFill, rFill;
        lFill = " ".repeat(Math.floorDiv(maxLength, 2));
        rFill = " ".repeat((int) Math.ceil((double) maxLength/2));

        String content =
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                   RESPONSE:                                  │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│"  + lFill + response + rFill + "│\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n";

        showInfoScreen(content);
    }

    /**
     * Prints a "info screen" to the console containing specific content as a message. It then awaits input from the
     * local user and returns it.
     *
     * @param content the specific content (message)
     *
     * @return the local user input
     */
    private String showInputScreen(String content) {
        Logger.getLogger().info("Showing \"input screen\".");
        System.out.println(UtilsCP.in01 + UtilsCP.in02 + content + UtilsCP.in03 + UtilsCP.in04 + UtilsCP.in05 + UtilsCP.in06);
        return scanner.nextLine().toLowerCase();
    }

    /**
     * Prints the "confirm screen" for exiting the program.
     *
     * @return the users decision, either true or false
     */
    private boolean showExitConfirmScreen() {
        Logger.getLogger().info("Show \"exit confirm screen\".");

        String content =
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                       Are you sure you want to exit                          │\n" +
                "│                                the program?                                  │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n";

        return showConfirmScreen(content);
    }

    /**
     * Prints a "confirm screen" to the console containing specific content as a message
     *
     * @param content the specific content (message)
     *
     * @return true, if user responded with "y" or "yes", false if user responded with "n" or "no"
     */
    private boolean showConfirmScreen(String content) {
        Logger.getLogger().info("Showing \"confirm screen\".");

        System.out.println(UtilsCP.c01 + UtilsCP.c02 + content + UtilsCP.c03 + UtilsCP.c04 + UtilsCP.c05 + UtilsCP.c06);

        String line = scanner.nextLine().toLowerCase();

        if(line.equals("y") || line.equals("yes")) {
            return true;
        } else if(line.equals("n") || line.equals("no")) {
            return false;
        } else {
            return showConfirmScreen(content);
        }
    }

    /**
     * Prints the "remote help screen" to the console
     */
    private void showRemoteHelpScreen() {
        Logger.getLogger().info("Showing \"remote help screen\".");

        String content =
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                        THIS IS THE REMOTE HELP SCREEN                        │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                    Nothing to see here yet, it just exists.                  │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n" +
                        "│                                                                              │\n";

        showInfoScreen(content);
    }

    /**
     * Prints the "help screen" to the console.
     */
    private void showHelpScreen() {
        Logger.getLogger().info("Showing \"help screen\".");

        String content =
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                           THIS IS THE HELP SCREEN                            │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                    Nothing to see here yet, it just exists.                  │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n";

        showInfoScreen(content);
    }

    /**
     * Prints the "about screen" to the console.
     */
    private void showAboutScreen() {
        Logger.getLogger().info("Showing \"about screen\".");

        String content =
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                           THIS IS THE ABOUT SCREEN                           │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                   In the future, this will tell you what this                │\n" +
                "│                              jazz is all about!                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n" +
                "│                                                                              │\n";

        showInfoScreen(content);
    }

    /**
     * Prints an "info screen" to the console containing specific content as a message.
     *
     * @param content the specific content (message)
     */
    private void showInfoScreen(String content) {
        Logger.getLogger().info("Showing \"info screen\".");

        System.out.println(UtilsCP.i01 + UtilsCP.i02 + content + UtilsCP.i03 + UtilsCP.i04 + UtilsCP.i05 + UtilsCP.i06);

        String line = scanner.nextLine();

        if(!line.equals("")) {
            showInfoScreen(content);
        }
    }

    /**
     * Print the "welcome screen" to the console for a fixed amount of time (specified by "WELCOME_SCREEN_TIME" above)
     * and initializes the required Git repositories by calling Git.initialize().
     */
    private void showWelcomeScreen() {
        Logger.getLogger().info("Showing \"welcome screen\".");

        System.out.println(
                UtilsCP.w01 + UtilsCP.w02 + UtilsCP.w03 + UtilsCP.w04 + UtilsCP.w05 + UtilsCP.w06 + UtilsCP.w07 +
                UtilsCP.w08 + UtilsCP.w09 + UtilsCP.w10 + UtilsCP.w11 + UtilsCP.w12 + UtilsCP.w13 + UtilsCP.w14 +
                UtilsCP.w15 + UtilsCP.w16 + UtilsCP.w17 + UtilsCP.w18 + UtilsCP.w19 + UtilsCP.w20 + UtilsCP.w21 +
                UtilsCP.w22 + UtilsCP.w23 + UtilsCP.w24);

        Git.initialize();
    }

    /**
     * Terminates all active modules and sets the boolean flag "exit" to true, indicating the ControlPanel
     * to terminate as well.
     */
    private void exit() {
        //Stop the hourly callback timer for slack logging
        timer.cancel();
        //Slack status message
        Slack.sendMessage("The *WhyInvestigator* application has been *terminated*. Bye!");

        if(remoteInputReceiver != null) {
            Logger.getLogger().info("Terminating the RemoteInputReceiver.");
            remoteInputReceiver.stopReceiver();
        }
        if(workerRunning) {
            Logger.getLogger().info("Terminating the SQLWorker.");
            workerRunning = false;
            worker.terminate();
        }
        if(watcherRunning) {
            Logger.getLogger().info("Terminating the FileWatcher.");
            watcherRunning = false;
            watcher.terminate();
        }
        if(processorRunning) {
            Logger.getLogger().info("Terminating the Processor");
            processorRunning = false;
            processor.terminate();
        }

        Logger.getLogger().info("Terminating the ControlPanel. Program exit.");

        exit = true;
    }

    /**
     * Loads the config file and parses "isMaster" from it.
     */
    private void loadConfig() {
        Logger.getLogger().config("Loading config for ControlPanel.");

        // Retrieve "workerConf" object from config json
        JSONObject controlConfig = FileManager.getConfigObject("controlConfig");

        isMaster = controlConfig.getBoolean("isMaster");
        Logger.getLogger().config("Retrieved \"isMaster\"=" + isMaster + " from the config file.");

        port = controlConfig.getInt("port");
        Logger.getLogger().config("Retrieved \"port\"=" + port + " from the config file.");

        // Slack
        String slackWebHookUrl = controlConfig.getString("slackWebHookUrl");
        Logger.getLogger().config("Retrieved \"slackWebHookUrl\"=" + slackWebHookUrl + " from the config file.");

        boolean slackLogging = controlConfig.getBoolean("slackLogging");
        Logger.getLogger().config("Retrieved \"slackLogging\"=" + slackLogging + " from the config file.");

        // Initialize slack logging
        Slack.initialize(slackWebHookUrl, slackLogging);

        delay = controlConfig.getLong("slackStatusDelay");
        Logger.getLogger().config("Retrieved \"slackStatusDelay\"=" + delay + " from the config file.");

        period = controlConfig.getLong("slackStatusPeriod");
        Logger.getLogger().config("Retrieved \"slackStatusPeriod\"=" + period + " from the config file.");

        // Retrieve "syncConfig" object from config json to access the user/pw required
        controlConfig = FileManager.getConfigObject("syncConfig");

        syncUser = controlConfig.getString("syncUser");
        Logger.getLogger().config("Retrieved \"syncUser\"=" + syncUser + " from the config file.");
        syncPass = controlConfig.getString("syncPass");
        Logger.getLogger().config("Retrieved \"syncPass\"=" + syncPass + " from the config file.");

        Logger.getLogger().config("Finished loading config for ControlPanel.");
    }

    public static void main(String[] args) {
        new ControlPanel();
    }
}
