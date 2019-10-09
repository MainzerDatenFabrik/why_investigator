package com.mainzerdatenfabrik.main.worker;

import com.mainzerdatenfabrik.main.file.FileManager;
import com.mainzerdatenfabrik.main.git.Git;
import com.mainzerdatenfabrik.main.logging.slack.Slack;
import com.mainzerdatenfabrik.main.module.ProgramModule;
import com.mainzerdatenfabrik.main.logging.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

public class SQLWorker extends ProgramModule {

    // A map holding references to all the workers that are created based on their name (i.e., the name of the thread)
    private static final HashMap<String, WorkerThread> workersMap = new HashMap<>();

    // Indicates that the workers should continue running. When this flag is set to false, on the next iteration
    // every worker will terminate.
    private boolean childrenRunning = true;

    /**
     * The Constructor.
     */
    public SQLWorker() {
        super("SQLWorkerOld");
    }

    /**
     * The overwritten run method.
     */
    @Override
    public void run() {
        loadConfig();

        try {
            while(running) {
                active = true;

                // Something to do here?

                if(running) {
                    int sleepTime = 60000;
                    Logger.getLogger().info("Sleeping for " + sleepTime + "ms.");
                    active = false;
                    Thread.sleep(sleepTime); // Todo: whats with this value? Add to config maybe?
                }
            }
        } catch (InterruptedException e) {
            //System.err.println("SQLWorker interrupted!");
        }

        Logger.getLogger().info("EXIT - Waiting for " + workersMap.size() + " workers to join, please be patient!");
        // Once the loop is done, signal all children not to continue working
        // and wait for them to join
        childrenRunning = false;

        // Interrupt all workers that are currently sleeping as there is no need to wait for them
        // as they are going to exit after sleeping anyways.
        // This speeds up the termination process of the SQLWorker instance.
        for(Map.Entry<String, WorkerThread> entry : workersMap.entrySet()) {
            WorkerThread worker = entry.getValue();
            if(!worker.isActive()) {
                worker.interrupt();
            }
        }
        Logger.getLogger().info("SQLWorker EXIT.");
    }

    /**
     * Used to load the "tasks" config from the config file. I.e., the "tasks" config is the config of the SQLWorkerOld.
     */
    @Override
    protected void loadConfig() {
        //Retrieve "sqlWorkerConfig" array from config
        JSONArray tasks = FileManager.getConfigArray("sqlWorkerConfig");

        for(int i = 0; i < tasks.length(); i++) {
            JSONObject task = tasks.getJSONObject(i);

            String host = task.getString("host");
            int port = task.getInt("port");
            int frequency = task.getInt("frequency");

            String sqlUsername = task.getString("username");
            String sqlPassword = task.getString("password");

            JSONArray libraries = task.getJSONArray("libraries");
            boolean user = false;
            boolean instance = false;
            boolean database = false;
            for(int j = 0; j < libraries.length(); j++) {
                String library = libraries.getString(j);
                switch (library) {
                    case "user": user = true; break;
                    case "instance": instance = true; break;
                    case "database": database = true; break;
                }
            }

            Logger.getLogger().info("host=" + host + ", port=" + port + ", freq=" + frequency + ", user=" + user
                    + ", instance=" + instance + ", database=" + database);

            //Slack status message
            Slack.sendMessage("*SQLWorker*: started new instance for: *{host: " + host + ", port: " + port + ", frequency: "
                    + frequency + ", user: " + user + ", databse: " + database + ", instance: " + instance + "}*");

            initializeWorker(new WorkerTask(this, sqlUsername, sqlPassword, host, port, frequency,
                    user, instance, database));
        }
    }

    /**
     * Used to create a new WorkerThread instance and initialize/start it with a specific WorkerTask instance. The
     * initialized worker is also added to the map of workers.
     *
     * @param task the task for the worker to perform. The tasks only differ in the specification for the connections
     *             and what checks to executed.
     */
    private void initializeWorker(WorkerTask task) {
        WorkerThread worker = new WorkerThread(task);
        workersMap.put(worker.getName(), worker);
        worker.start();
    }

    /**
     * The entry point for the program.
     */
    public static void main(String[] args) {
        Git.initialize();
        SQLWorker worker = new SQLWorker();
        worker.start();
    }

    /**
     * Indicates weather or not the children (worker thread instances) should (continue to) run.
     *
     * @return true, if the children are/should continue running, else false
     */
    public boolean isChildrenRunning() {
        return childrenRunning;
    }

    /**
     * Updates the "active" boolean flag of a specific WorkerThread instance based on the name of the instance.
     *
     * @param name the name of the WorkerThread instance, i.e., the identifier
     * @param active the value to update the boolean flag of the worker with
     */
    public void updateWorkerStatus(String name, boolean active) {
        workersMap.get(name).setActive(active);
    }
}
