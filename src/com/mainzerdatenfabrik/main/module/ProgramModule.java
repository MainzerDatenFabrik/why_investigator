package com.mainzerdatenfabrik.main.module;

import com.mainzerdatenfabrik.main.logging.Logger;
import com.mainzerdatenfabrik.main.logging.slack.Slack;
import com.mainzerdatenfabrik.main.utils.Utils;

import java.util.logging.Level;

public abstract class ProgramModule extends Thread {

    // The boolean flag indicating if a ProgramModule should still continue running. If it is set to false,
    // every module will exit the "main loop" it is in on the start of the next iterations.
    protected boolean running = true;

    // The boolean flag indicating if a ProgramModule is active (i.e., not sleeping) or not. This is used to determine
    // if a module can be interrupted safely to speed up the termination process or not.
    protected boolean active = true;

    /**
     * The constructor.
     */
    public ProgramModule(String name) {
        super(name);
    }

    /**
     * Sets the running boolean flag to false, causing the ProgramModule the method was called on to exit its
     * "main loop" on the start of the next iteration.
     * Acts as the initiation of the "Shutdown-Hook" for every ProgramModule to use in the Console Control Panel.
     */
    public void terminate() {
        running = false;

        if(!isActive()) {
            interrupt();
        }
    }

    /**
     * Makes the ProgramModule sleep if it is supposed to (i.e., if running) for a specific amount of time (in minutes).
     *
     * @param name      the name of the ProgramModule
     * @param sleepTime the specific amount of time to sleep in minutes
     */
    protected void sleep(String name, int sleepTime) {
        if(running) {
            active = false;

            //Slack status message
            Slack.sendMessage("*" + name + "*: Sleeping for *" + sleepTime + "* minutes.");
            Logger.getLogger().info("Sleeping for " + sleepTime + " minutes.");
            try {
                Thread.sleep(Utils.MS_PER_MIN * sleepTime);
            } catch (InterruptedException e) {
                Logger.getLogger().severe("ProgramModule " + name + " interrupted while sleeping!");
                Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
            }
        }
    }

    /**
     * Loads the data specified in the config file for the program.
     */
    protected abstract void loadConfig();

    /**
     * Indicates if a ProgramModule instance is active (i.e., if it is sleeping or not)
     *
     * @return true, if the thread is active, false if it is sleeping
     */
    public boolean isActive() {
        return active;
    }
}
