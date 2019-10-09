package com.mainzerdatenfabrik.main.git;

import com.mainzerdatenfabrik.main.file.FileManager;
import com.mainzerdatenfabrik.main.shell.Shell;
import com.mainzerdatenfabrik.main.logging.Logger;
import com.mainzerdatenfabrik.main.utils.Utils;
import org.json.JSONObject;

import java.io.File;

public class Git {

    // The message retrieved from "git status" when executed in a clean working directory
    private static final String GIT_STATUS_MESSAGE_CLEAN = "nothing to commit, working tree clean";

    // The clone url of the git repository
    private static String gitRepositoryCloneURL;
    // The local path of the git repository
    private static String gitRepositoryLocalPath;
    // The url of the git repository
    private static String gitRepositoryURL;


    // The git repository as a file
    private static File gitRepository;

    // Indicates weather or not the git class has been initialized or not
    private static boolean initialized = false;

    /**
     * Creates a new branch based on a specific branch name in combination of the current datetimeid (now), sets the
     * upstream of it, adds all files to the branch, commits and pushes it. Finally, the created branch is merged
     * with the master branch.
     *
     * @param branchName the identifier for the branch (e.g., "SQLProcessor" --> "SQLProcessor_2019000000")
     */
    public static void pushToBranchAndMerge(String branchName) {
        if(!Git.status()) {
            String branch = branchName + "_" + Utils.getDatetimeId(Utils.DATE_TIME_FORMAT.format(new java.util.Date()));

            Git.checkoutNewBranch(branch);
            Git.pushSetUpstream(branch);
            Git.addAll();
            Git.commit("Processor committing processed logs.");
            Git.push();
            Git.checkoutMaster();
            Git.merge(branch);
            Git.push();

            Git.createFolders(); // Todo: who ever needs these folders should create them if they are not present!
        }
    }

    /**
     * Must be called on program start. Initializes git usage by parsing necessary information from the config
     * and creating file structures.
     * If the git repository specified in the config file is not yet locally present, it is created, initialized
     * and cloned.
     * If it does already exist, it is pulled to update recent changes.
     */
    public static void initialize() {
        Logger.getLogger().config("Loading config for Git.");
        // Retrieve the config object from the config file
        JSONObject gitConfig = FileManager.getConfigObject("gitConfig");

        gitRepositoryCloneURL = gitConfig.getString("repoCloneURL");
        Logger.getLogger().config("Retrieved \"gitRepositoryCloneURL\"=" + gitRepositoryCloneURL + " from config.");
        gitRepositoryLocalPath = gitConfig.getString("repoPath");
        Logger.getLogger().config("Retrieved \"gitRepositoryLocalPath\"=" + gitRepositoryLocalPath + " from config.");
        gitRepositoryURL = gitConfig.getString("repoURL");
        Logger.getLogger().config("Retrieved \"gitRepositoryURL\"=" + gitRepositoryURL + " from config.");

        gitRepository = new File(gitRepositoryLocalPath);

        // If the repository does not exits locally yet, clone it
        // else, update the state by pulling
        if(!gitRepository.exists()) {
            Logger.getLogger().config("Initializing and cloning local git repository.");
            if(FileManager.makeDirectory(gitRepositoryLocalPath)) {
                initRepository();
                cloneRepository();
            }
        } else {
            Logger.getLogger().config("Updating local git repository by pulling.");
            pull();
        }

        createFolders();

        initialized = true;
        Logger.getLogger().config("Finished loading config for Git.");
    }

    /**
     * Creates the file structure required for usage of git.
     *
     * The modules each need their own folder to place collected data in. The Processor needs the "Processed" and
     * "Error" folders.
     *
     */
    public static void createFolders() {
        FileManager.makeDirectory(gitRepositoryLocalPath + "/SQLWorker");
        FileManager.makeDirectory(gitRepositoryLocalPath + "/FileWatcher");
        FileManager.makeDirectory(gitRepositoryLocalPath + "/Processed");
        FileManager.makeDirectory(gitRepositoryLocalPath + "/Error");
    }

    /**
     * Default wrapper of the "status(File)" method below.
     */
    public static boolean status() {
        return status(gitRepository);
    }

    /**
     * Used to retrieve the status of a specific directory (i.e., a git repository).
     *
     * @param directory the directory the command is executed in
     *
     * @return true, if "git status" returns local changes, false else
     */
    public static boolean status(File directory) {
        Logger.getLogger().info("Retrieving the status of the git repository: " + directory.getAbsolutePath() + ".");

        String output = Shell.executeInfoCommand(gitRepository, "git", "status");
        Logger.getLogger().info("OUTPUT: " + output);

        return output.contains(GIT_STATUS_MESSAGE_CLEAN);
    }

    /**
     * Default wrapper of the "deleteBranch(File, String)" method below.
     */
    public static void deleteBranch(String branch) {
        deleteBranch(gitRepository, branch);
    }

    /**
     * Used to delete a specific branch.
     *
     * @param directory the directory to execute the command in
     * @param branch the name of the branch to delte
     */
    public static void deleteBranch(File directory, String branch) {
        Logger.getLogger().info("Deleting branch: " + branch + ".");
        Shell.executeCommand(directory, "git", "branch", "-d", branch);
    }

    /**
     * Default wrapper of the "checkout(File, String)" method below.
     */
    public static void checkout(String branch) {
        checkout(gitRepository, branch);
    }

    /**
     * Used to switch the branch currently on.
     *
     * @param directory the directory to execute the command in (i.e., the git repository)
     * @param branch the name of the branch to switch to (e.g., "master")
     */
    public static void checkout(File directory, String branch) {
        Logger.getLogger().info("Switching current branch to: " + branch + ".");
        Shell.executeCommand(directory, "git", "checkout", branch);
    }

    /**
     * Default wrapper of the "checkoutMaster" method below.
     */
    public static void checkoutMaster() {
        checkout("master");
    }

    /**
     * Default wrapper of the "pushSetUpstream(File, String)" method below.
     */
    public static void pushSetUpstream(String branch) {
        pushSetUpstream(gitRepository, branch);
    }

    /**
     * Used to push a newly created branch and set its upstream at the same time.
     * @param directory the directory to execute the command in (i.e., the local git repository)
     * @param branch the name of the branch to set the upstream for
     */
    public static void pushSetUpstream(File directory, String branch) {
       Logger.getLogger().info("Setting the upstream of branch: " + branch + ".");
       Shell.executeCommand(directory, "git", "push", "--set-upstream", "origin", branch);
    }

    /**
     * Default wrapper method of the "merge(File, String)" method below.
     */
    public static void merge(String branch) {
        merge(gitRepository, branch);
    }

    /**
     * Used to merge a specific branch and the master branch.
     *
     * @param directory i.e., the local git repository
     * @param branch the name of the branch to merge with master
     */
    public static void merge(File directory, String branch) {
        Logger.getLogger().info("Merging branch: " + branch + " with master.");
        Shell.executeCommand(directory, "git", "merge", branch);
    }

    /**
     * Default wrapper method of the "checkout(File, String)" method below.
     */
    public static void checkoutNewBranch(String branch) {
       checkoutNewBranch(gitRepository, branch);
    }

    /**
     * Used to create a new branch and switch to it in a specific directory.
     *
     * @param directory the specific directory (i.e., the git repository to create the new branch for)
     * @param branch the name of the new branch to create
     */
    public static void checkoutNewBranch(File directory, String branch) {
        Logger.getLogger().info("Creating and switching to new branch: " + branch + ".");
        Shell.executeCommand(directory, "git", "checkout", "-b", branch);
    }

    /**
     * Default wrapper method of the "initRepository(String)" method below.
     */
    public static void initRepository() {
        init(gitRepository.getParentFile());
    }

    /**
     * Used to initialize specific directory for the usage of git.
     *
     * @param directory the directory to initialize
     */
    public static void init(File directory) {
        Logger.getLogger().info("Initializing repository for git usage: " + directory.getAbsolutePath() + ".");
        Shell.executeCommand(directory, "git", "init");
    }

    /**
     * Default wrapper method of the "cloneRepository(String, String)" method below.
     */
    public static void cloneRepository() {
        cloneRepository(gitRepository.getParentFile(), gitRepositoryCloneURL);
    }

    /**
     * Used to execute a "git clone" command on a specific directory using a specific git repository url.
     *
     * @param directory the path of the directory the repository is cloned to
     * @param url the url of the repository to clone
     */
    public static void cloneRepository(File directory, String url) {
        Logger.getLogger().info("Cloning repository " + url + " to: " + directory);
        Shell.executeCommand(directory, "git", "clone", url);
    }

    /**
     * Default wrapper method of the "pull(String)" method below.
     */
    public static void pull() {
        pull(gitRepository);
    }

    /**
     * Used to execute a "git pull" command on a specific directory.
     *
     * @param directory the path of the directory to execute the command in
     */
    public static void pull(File directory) {
        Logger.getLogger().info("Pulling in directory: " + directory + ".");
        Shell.executeCommand(directory, "git", "pull");
    }

    /**
     * Default wrapper method of the "add(String)" method below.
     */
    public static void add(String filename) {
        add(gitRepository, filename);
    }

    /**
     * Used to execute a "git add -A" command on a specific directory.
     *
     * @param directory the specific directory to execute the command in
     */
    public static void add(File directory, String filename) {
        Logger.getLogger().info("Adding " + filename + " in directory: " + directory + ".");
        Shell.executeCommand(directory, "git", "add", filename);
    }

    /**
     * Default Wrapper of the "addAll(File)" method below.
     */
    public static void addAll() {
        addAll(gitRepository);
    }

    /**
     * Used to add all files to git inside of a specific git repository.
     *
     * @param directory the local git repository
     */
    public static void addAll(File directory) {
        Logger.getLogger().info("Adding all files in directory: " + directory + ".");
        Shell.executeCommand(directory, "git", "add", "-A");
    }

    /**
     * Default wrapper method of the "commit(String, String)" method below.
     */
    public static void commit(String message) {
        commit(gitRepository, message);
    }

    /**
     * Used to execute a "git commit -m" command on a specific directory with a specific message.
     *
     * @param directory the specific directory to execute the command in
     * @param message the specific message contained in the commit
     */
    public static void commit(File directory, String message) {
        Logger.getLogger().info("Committing in directory " + directory + " with message: " + message);
        Shell.executeCommand(directory, "git", "commit", "-m", message);
    }

    /**
     * Default wrapper method of the "push(String)" method below.
     */
    public static void push() {
        push(gitRepository);
    }

    /**
     * Used to execute a "git push" command on a specific directory.
     *
     * @param directory the specific directory to execute the command in
     */
    public static void push(File directory) {
        Logger.getLogger().info("Pushing changes in directory: " + directory + ".");
        Shell.executeCommand(directory, "git", "push");
    }

    /**
     *
     * @return the local path of the git repository as string
     */
    public static String getGitRepositoryLocalPath() {
        return gitRepositoryLocalPath;
    }

    /**
     *
     * @return the clone url of the git repository as string
     */
    public static String getGitRepositoryCloneURL() {
        return gitRepositoryCloneURL;
    }

    /**
     *
     * @return the url of the git repository as string
     */
    public static String getGitRepositoryURL() {
        return gitRepositoryURL;
    }
}
