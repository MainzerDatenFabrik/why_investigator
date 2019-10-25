# WHY_INVESTIGATOR 
> Investigate your SQL Server environment.

## Content
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Legal Information](#user-content-legal-information)
- [Further Information](#user-content-further-information)

## Features

> Video coming soon.

The **WHY_INVESTIGATOR** is a fully automated, platform independent tool for documenting **SQL Server** environments. The independency of the underlying operating system makes it especially easy to deploy the tool to any server system desired.
Once the **WHY_INVESTIGATOR** has been deployed, the tool can be configured to monitor any server in the environment, no matter how many there are.
The gathered data is collected/managed in small JSON files locally to prevent loss of information and grant data integrity.

The **WHY_INVESTIGATOR** is multi modular and currently consist of three modules.

* **SQL Worker**

> Graphic for the SQL Worker coming soon.

  The SQL Worker module is used for gathering the information from the sql server environment. It consists of a library containing a multitude of queries concerning the configuration, state, hardware, users, databases, health, changes, etc. of the SQL Server.
  The gathered information for each server is stored locally in small JSON files and paired with a checksum to guarantee data integrity. 

* **Processor**
  
> Graphic for the Processor coming soon.

  The Processor module is used for processing the data gathered by the SQL Worker into a database of choice.

* **File Watcher**

> **Currently under development. Coming soon.**
> Graphic for the File Watcher coming soon.

  The FileWatcher module is used for documenting the operating system environment the WHY_INVESTIGATOR resides in. It is a file crawler, observing a desired directory documenting all changes, new file creations, deletions and updates. It stores the gathered information in the same way the SQL Worker does: small JSON files are created locally and paired with a checksum to guarantee data integrity.

## Installation

### Clone

Clone this repository to your local machine by either using https `https://github.com/MainzerDatenFabrik/why_investigator.git` or ssh `git@github.com:MainzerDatenFabrik/why_investigator.git` and get started.

### Setup

> Coming soon.

### Dependencies
- Java SDK 11.0.2 or higher
- JDBC 7.2
	- mssql-jdbc-7.2.1.jre11.jar
	- sqljdbc_auth.dll
- JSON json-20180813.jar
- Git
- commons-logging-1.1.2
- httpclient-4.5.8
- httpcore-4.4.11
- jackson-annotations-2.9.8
- jackson-core-2.9.2
- jackson-databind-2.9.8
- lombok

### Execute

> Coming soon.

## Usage

The **WHY_INVESTIGATOR** is controlled by a simple and intuitive console interface. Once the application has been started, the loading screen will appear, initializing the required repositories and updating them.
After the repositories have been initialized, the main interface will appear, presenting multiple operations to choose from. Any presented command can be typed directly into the command prompt and can be confirmed by hitting enter. Additionally, there are shortcuts available for all commands, indicated by the brackets around a single letter or number (e.g., "[H] Help" -> either "Help", "help" or "h").

### Config file

```
{
	"sqlWorkerConfig": [                				// the configuration for the sql worker module
	      {                             				// start of a single host object to observe
            "host":"examplehost.com",       				// the ip address of the server to observe
            "port":1433,                    				// the port of the sql server instance (default 1433)
            "frequency":30,                 				// the amount of time to sleep between iterations (i.e., execute every 30 minutes)
            "username":"example_username",  				// the sql username for the sql worker module to use -> this can be left empty if AD-Authentication is used
            "password":"example_password",  				// the sql password for the sql worker module to use -> this can be left empty if AD-Authentication is used
            "libraries": [                  				// what data to collect from the instance
                "user",                     				// <- data concerning information about users (logins, roles, changes, etc.)
                "instance",                 				// <- data concerning information about the instance itself (hardware, state, connectivity, etc.)
                "database"                  				// <- data concerning information about the databases of the instance (dbs, tables, changes, etc.)
        	]
        },                                  				// end of a single host object to observe
        {                                   				// start of another single host object to observe 
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
        }                                   				// end of another single host object to observe
	],                                        			// end of the sql worker module configuration
	"processorConfig" : {						// the configuration for the processor module
	    "fileDirectory":"/home/projektwhy/filestat2",		// the path to the git repository used for managing local JSON files
	    "outDirectory":"/home/projektwhy/filestat2/Processed",	// the path ot the git repository directory to store already processed files
	    "errorDirectory":"/home/projektwhy/filestat2/Error",	// the path to the git repository directory to store files that were unable to be processed
	    "hostName":"localhost",					// the ip address of the sql server to process the gathered data to
	    "port":1433,						// the port of the sql server to process the gathered data to
	    "targetDatabaseName":"why_investigator_stage",		// the name of the database to process the gathered data to
	    "username":"",						// the sql username for the processor module to use -> this can be left empty if AD-Authentication is used
            "password":"",						// the sql password for the processor module to use -> this can be left empty if AD-Authentication is used
	    "sleepTime":10						// the amount of time for the module to sleep in between iterations in minutes
	}, 								// end of the processor module config
	"fileWatcherConfig" : {						// the configuration for the file watcher module
	    "observedDirectory":"Z:/test/observed",			// the path to the directory for the file watcher module to observe
	    "serverName":"qeo003.server.local",			// 
	    "sleepTime":30000						//
	},								// end of the file watcher module config
	"gitConfig" : {							// the configuration for Git
	    "repoCloneURL":"https://yourclone.filestat2.git", // the clone url for the repository to store the local data in
	    "repoPath":"/home/projektwhy/filestat2",			// the path to the repository to store the local data in
	    "repoURL":"https://bitbucket.org/repo/filestat2"	// the url of the repository to store the local data in
	},								// end of the Git config
	"controlConfig": {						// the configuration for the control panel interface
	    "isMaster":true,						// indicates permission to use the remote control interface
	    "port":8787,						// the port for the remote control interface
	    "slackLogging":true,					// whether or not slack status messages are sent or not
	    "slackStatusDelay":3600000,					// the slack status message delay 
	    "slackStatusPeriod":3600000,				// the slack status message period
	    "slackWebHookUrl":"https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXXXXXXXX", // the slack token for slack integration
	},
}

```

## Legal Information

### Copyright Information
 MIT License

Copyright (c) 2019 Mainzer Datenfabrik GmbH

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### Trademark Information
Any trademarks contained in the source code, binaries, and/or in the documentation, are the sole property of their respective owners.

## Further Information

www.mainzerdatenfabrik.de
