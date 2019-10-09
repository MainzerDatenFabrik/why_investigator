package com.mainzerdatenfabrik.main.worker;

/**
 * Implementation of a basic "Thread" with an additional status string.
 *
 * @author Aaron Priesterroth
 */
public class WorkerThread extends Thread {

    private boolean active = false;

    /**
     * The Constructor.
     *
     * @param workerTask the task for the worker (i.e., a runnable with a certain procedure for every worker to follow)
     */
    public WorkerThread(WorkerTask workerTask) {
        super(workerTask);
        // Every worker is a daemon
        setDaemon(true);
    }

    /**
     * Indicates if a WorkerThread instance is active (i.e., if it is sleeping or not)
     *
     * @return true, if the thread is active, false if it is sleeping
     */
    public boolean isActive() {
        return active;
    }

    /**
     * Updates the "active" status of a worker to a specific value.
     *
     * @param active the specific value to update the workers status with
     */
    public void setActive(boolean active) {
        this.active = active;
    }
}
