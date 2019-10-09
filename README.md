# WHY_INVESTIGATOR 
> Investigate your SQL Server environment.

## I. Content
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Legal Information](#user-content-legal-information)
- [Further Information](#user-content-further-information)

## Features

The **WHY_INVESTIGATOR** is a fully automated, platform independent tool for documenting **SQL Server** environments. The independency of the underlying operating system makes it especially easy to deploy the tool to any server system desired.
Once the **WHY_INVESTIGATOR** has been deployed, the tool can be configured to monitor any server in the environment, no matter how many there are.
The gathered data is collected/managed in small JSON files locally to prevent loss of information and grant data integrity.

The **WHY_INVESTIGATOR** is multi modular and currently consist of three modules.

* **SQL Worker**

  The SQL Worker module is used for gathering the information from the sql server environment. It consists of a library containing a multitude of queries concerning the configuration, state, hardware, users, databases, health, changes, etc. of the SQL Server.
  The gathered information for each server is stored locally in small JSON files and paired with a checksum to guarantee data integrity. 

* **Processor**
  
  The Processor module is used for processing the data gathered by the SQL Worker into a database of choice.

* **FileWatcher**

  > **Currently under development. Coming soon.**

  The FileWatcher module is used for documenting the operating system environment the WHY_INVESTIGATOR resides in. It is a file crawler, observing a desired directory documenting all changes, new file creations, deletions and updates. It stores the gathered information in the same way the SQL Worker does: small JSON files are created locally and paired with a checksum to guarantee data integrity.

## Installation

### Requirements

> Coming soon.

- Java 
- Git

### Clone

Clone this repository to your local machine using
- ssh: `git@github.com:MainzerDatenFabrik/why_investigator.git`
- Https: `https://github.com/MainzerDatenFabrik/why_investigator.git`

### Setup

> Coming soon.

To build the project, naviagte into the previously cloned repository and execute `javac *.java`.

### Dependencies

> Coming soon.

The following dependencies are required to compile the project:
- 
-
-

### Execute

> Coming soon.

To start the previuously compiled application, use the command `java -jar `.

## Usage

The **WHY_INVESTIGATOR** is controlled by a simple and intuitive console interface. Once the application has been started, the loading screen will appear, initializing the required repositories and updating them.
After the repositories have been initialized, the main interface will appear, presenting multiple operations to choose from. Any presented command can be typed directly into the command prompt and can be confirmed by hitting enter. Additionally, there are shortcuts available for all commands, indicated by the brackets around a single letter or number (e.g., "[H] Help" -> either "help" or "h").

### Config file

> Coming soon.

```
{
	"sqlWorkerConfig": [                // the configuration for the sql worker module
	      {                             // start of a single host object to observe
            "host":"examplehost.com",       // the ip address of the server to observe
            "port":1433,                    // the port of the sql server instance (default 1433)
            "frequency":30,                 // the amount of time to sleep between iterations (i.e., execute every 30 minutes)
            "username":"example_username",  // the sql username for the sql worker module to use -> this can be left empty if AD-Authentication is used
            "password":"example_password",  // the sql password for the sql worker module to use -> this can be left empty if AD-Authentication is used
            "libraries": [                  // what data to collect from the instance
                "user",                     // <- data concerning information about users (logins, roles, changes, etc.)
                "instance",                 // <- data concerning information about the instance itself (hardware, state, connectivity, etc.)
                "database"                  // <- data concerning information about the databases of the instance (dbs, tables, changes, etc.)
        	]
        },                                  // end of a single host object to observe
        {                                   // start of another single host object to observe 
            "host":"examplehost2.com",
            "port":1433,
            "frequency":30,
            "username":"example_user",
            "password":"example_password",
            "libraries": [
                "user",
                "instance",
                "database"
            ]
        }                                   // end of another single host object to observe
	],                                        // end of the sql worker module config
	"processorConfig" : {						// the configuration for the processor module
	    "fileDirectory":"/home/projektwhy/filestat2",		// the path to the git repository used for managing local JSON files
	    "outDirectory":"/home/projektwhy/filestat2/Processed",	// the path ot the git repository folder to store already 
	    "errorDirectory":"/home/projektwhy/filestat2/Error",	// 
	    "hostName":"localhost",
	    "port":1433,
	    "targetDatabaseName":"why_investigator_stage",
	    "username":"sa",
        "password":"L37Mainz05",
	    "sleepTime":10
	},
	"fileWatcherConfig" : {
	    "observedDirectory":"Z:/test/observed",
	    "serverName":"qeo003.schackenberg.local",
	    "sleepTime":30000
	},
	"gitConfig" : {
	    "repoCloneURL":"https://aaronsch@bitbucket.org/schackenberg/filestat2.git",
	    "repoPath":"/home/projektwhy/filestat2",
	    "repoURL":"https://bitbucket.org/schackenberg/filestat2"
	},
	"controlConfig": {
	    "isMaster":true,
	    "port":8787,
	    "slackLogging":true,
	    "slackStatusDelay":3600000,
	    "slackStatusPeriod":3600000,
	    "slackWebHookUrl":"https://hooks.slack.com/services/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",
	    "syncUser":"whyinvestigator",
	    "syncPass":"Start123",
	},
	"syncConfig": {
	    "syncUser":"whyinvestigator",
	    "syncPass":"Start123",
	    "sleepTime":10
	}
}

```

## Legal Information

### Copyright Information
 > Coming soon.

### Trademark Information
Any trademarks contained in the source code, binaries, and/or in the documentation, are the sole property of their respective owners.

## Further Information

www.mainzerdatenfabrik.de
