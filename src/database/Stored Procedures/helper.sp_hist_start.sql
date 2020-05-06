SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [helper].[sp_hist_start]
AS
BEGIN

    DECLARE @deployment_id UNIQUEIDENTIFIER;

    -- create new deployment id for current start
    SET @deployment_id = NEWID();

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistDeploymentId'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistDeploymentId]
        (
            [timestamp] [DATETIME] NOT NULL,
            [id] INT IDENTITY(1, 1) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL,
            [user_name] [NVARCHAR](1000) NOT NULL
        );
    -- DROP TABLE [helper].[HistDeploymentId]
    END;

    -- store the current deployment id in the table
    INSERT INTO [helper].[HistDeploymentId]
    (
        [timestamp],
        [deployment_id],
        [user_name]
    )
    SELECT GETDATE(),
           @deployment_id,
           ORIGINAL_LOGIN();

    -- Databases

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistDatabases'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistDatabases]
        (
            [timestamp] [DATETIME] NOT NULL,
            [database_name] [NVARCHAR](1000) NOT NULL,
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL
        );
    END;

    -- store the name of all databases currently present on the system in the table 
    INSERT INTO [helper].[HistDatabases]
    (
        [timestamp],
        [database_name],
        [deployment_type],
        [deployment_id]
    )
    SELECT GETDATE(),
           [name],
           'START',
           @deployment_id
    FROM sys.databases
    WHERE [database_id] NOT IN ( 1, 2, 3, 4 )
          AND name NOT IN ( 'DWConfiguration', 'DWDiagnostics', 'DWQueue' );

    -- Logins

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistLogins'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistLogins]
        (
            [timestamp] [DATETIME] NOT NULL,
            [login_name] [NVARCHAR](1000) NOT NULL,
            [object_definition] [NVARCHAR](MAX) NULL,
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL
        );
    END;


    DECLARE @SID_varbinary VARBINARY(85);
    DECLARE @SID_string VARCHAR(514);
    DECLARE @type VARCHAR(1);
    DECLARE @is_disabled INT;
    DECLARE @defaultdb sysname;
    DECLARE @hasaccess INT;
    DECLARE @denylogin INT;
    DECLARE @tmpstr VARCHAR(1024);
    DECLARE @PWD_varbinary VARBINARY(256);
    DECLARE @PWD_string VARCHAR(514);
    DECLARE @is_policy_checked VARCHAR(3);
    DECLARE @is_expiration_checked VARCHAR(3);
    DECLARE @stringToExecute NVARCHAR(MAX);
    DECLARE @name NVARCHAR(2000);

	DECLARE @bulkadmin int
	DECLARE @dbcreator int
	DECLARE @diskadmin int
	DECLARE @processadmin int
	DECLARE @setupadmin int
	DECLARE @serveradmin int
	DECLARE @securityadmin int
	DECLARE @sysadmin int

    DECLARE login_cursor CURSOR FOR(
    SELECT DISTINCT
           l.sid,
           l.name,
           p.type,
           p.is_disabled,
           p.default_database_name,
           l.hasaccess,
           l.denylogin,
		   l.bulkadmin,
		   l.dbcreator,
		   l.diskadmin,
		   l.processadmin,
		   l.setupadmin,
		   l.serveradmin,
		   l.securityadmin,
		   l.sysadmin
    FROM sys.syslogins l
        LEFT JOIN sys.server_principals p
            ON (l.name = p.name)
    WHERE p.type IN ( 'S', 'G', 'U' )
          AND l.name <> 'sa');
    OPEN login_cursor;

    -- Recreate create statement for all logins currently present on the system and store them in the table
    FETCH NEXT FROM login_cursor
    INTO @SID_varbinary,
         @name,
         @type,
         @is_disabled,
         @defaultdb,
         @hasaccess,
         @denylogin,
		 @bulkadmin,
		 @dbcreator,
		 @diskadmin,
		 @processadmin,
		 @setupadmin,
		 @serveradmin,
		 @securityadmin,
		 @sysadmin
    IF (@@fetch_status = -1)
    BEGIN
        PRINT 'Exception occurred while retrieving login cursor.';
    END;
    WHILE (@@fetch_status <> -1)
    BEGIN
        IF (@@fetch_status <> -2)
        BEGIN
            IF (@type IN ( 'G', 'U' ))
            BEGIN
                SET @tmpstr = 'CREATE LOGIN ' + @name + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']';
            END;
            ELSE
            BEGIN

                SET @PWD_varbinary = CAST(LOGINPROPERTY(@name, 'PasswordHash') AS VARBINARY(256));
                EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT;
                EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT;

                SELECT @is_policy_checked = CASE is_policy_checked
                                                WHEN 1 THEN
                                                    'ON'
                                                WHEN 0 THEN
                                                    'OFF'
                                                ELSE
                                                    NULL
                                            END
                FROM sys.sql_logins
                WHERE name = @name;
                SELECT @is_expiration_checked = CASE is_expiration_checked
                                                    WHEN 1 THEN
                                                        'ON'
                                                    WHEN 0 THEN
                                                        'OFF'
                                                    ELSE
                                                        NULL
                                                END
                FROM sys.sql_logins
                WHERE name = @name;

                SET @tmpstr
                    = 'CREATE LOGIN ' + @name + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string
                      + ', DEFAULT_DATABASE = [' + @defaultdb + ']';

                IF (@is_policy_checked IS NOT NULL)
                BEGIN
                    SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked;
                END;
                IF (@is_expiration_checked IS NOT NULL)
                BEGIN
                    SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked;
                END;
            END;

            IF (@denylogin = 1)
            BEGIN
                SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ''' + @name + ''' ';
            END;
            ELSE IF (@hasaccess = 0)
            BEGIN
                SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ''' + @name + ''' ';
            END;

            IF (@is_disabled = 1)
            BEGIN
                SET @tmpstr = @tmpstr + '; ALTER LOGIN ''' + @name + ''' DISABLE';
            END;

			IF(@bulkadmin = 1)
			BEGIN
				SET @tmpstr = @tmpstr + '
				
				ALTER SERVER ROLE bulkadmin ADD MEMBER ' + @name + '
				GO'
			END;

			IF(@dbcreator = 1)
			BEGIN
				SET @tmpstr = @tmpstr + '
				
				ALTER SERVER ROLE dbcreator ADD MEMBER ' + @name + '
				GO'
			END;

			IF(@diskadmin = 1)
			BEGIN
				SET @tmpstr = @tmpstr + '
				
				ALTER SERVER ROLE diskadmin ADD MEMBER ' + @name + '
				GO'
			END;

			IF(@processadmin = 1)
			BEGIN
				SET @tmpstr = @tmpstr + '
				
				ALTER SERVER ROLE processadmin ADD MEMBER ' + @name + '
				GO'
			END;

			IF(@setupadmin = 1)
			BEGIN
				SET @tmpstr = @tmpstr + '
				
				ALTER SERVER ROLE setupadmin ADD MEMBER ' + @name + '
				GO'
			END;

			IF(@serveradmin = 1)
			BEGIN
				SET @tmpstr = @tmpstr + '
				
				ALTER SERVER ROLE serveradmin ADD MEMBER ' + @name + '
				GO'
			END;

			IF(@securityadmin = 1)
			BEGIN
				SET @tmpstr = @tmpstr + '
				
				ALTER SERVER ROLE securityadmin ADD MEMBER ' + @name + '
				GO'
			END;

			IF(@sysadmin = 1)
			BEGIN
				SET @tmpstr = @tmpstr + '
				
				ALTER SERVER ROLE sysadmin ADD MEMBER ' + @name + '
				GO'
			END;

            INSERT INTO [helper].[HistLogins]
            (
                [timestamp],
                [login_name],
                [object_definition],
                [deployment_type],
                [deployment_id]
            )
            SELECT GETDATE(),
                   @name,
                   @tmpstr,
                   'START',
                   @deployment_id;

            FETCH NEXT FROM login_cursor
            INTO @SID_varbinary,
				 @name,
				 @type,
				 @is_disabled,
				 @defaultdb,
				 @hasaccess,
				 @denylogin,
				 @bulkadmin,
				 @dbcreator,
				 @diskadmin,
				 @processadmin,
				 @setupadmin,
				 @serveradmin,
				 @securityadmin,
				 @sysadmin;
        END;
    END;
    CLOSE login_cursor;
    DEALLOCATE login_cursor;

    -- Agent Jobs

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistAgentJobs'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistAgentJobs]
        (
            [timestamp] [DATETIME] NOT NULL,
            [job_name] [NVARCHAR](1000) NOT NULL,
			[job_definition] [NVARCHAR](max) NOT NULL,
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NULL
        );
    END;
	
	DECLARE @sqlstate_Agent AS NVARCHAR(MAX)
        = ('USE msdb

Declare @PRIMCount as int
Declare @SECONDCount as int

DECLARE @job_id UNIQUEIDENTIFIER
DECLARE @enabled BIT
DECLARE @notify_level_eventlog INT
DECLARE @notify_level_email INT
DECLARE @notify_level_netsend INT
DECLARE @notify_level_page INT
DECLARE @delete_level INT
DECLARE @description NVARCHAR(1024)
DECLARE @category_name sysname
DECLARE @owner_login_name sysname

DECLARE @step_id INT
DECLARE @step_name sysname
DECLARE @command NVARCHAR(MAX)
DECLARE @additional_parameters NVARCHAR(MAX)
DECLARE @cmdexec_success_code INT
DECLARE @on_success_action TINYINT
DECLARE @on_success_step_id INT
DECLARE @on_fail_action TINYINT
DECLARE @on_fail_step_id INT
DECLARE @retry_attempts INT
DECLARE @retry_interval INT
DECLARE @os_run_priority INT
DECLARE @subsystem NVARCHAR(80)
DECLARE @server sysname
DECLARE @database_name sysname
DECLARE @database_user_name sysname
DECLARE @flags INT
DECLARE @proxy_name sysname
DECLARE @output_file_name NVARCHAR(400)
DECLARE @countsql int
DECLARE @CHECHAVG INT

DECLARE @date_created datetime
DECLARE @date_modified datetime

Declare @SQLState nvarchar(max)
DECLARE @JobName sysname

DECLARE @SQL NVARCHAR(MAX)

SET @CHECHAVG =
(
SELECT COUNT(*) as PRIMARY_COMPUTE
            FROM sys.dm_hadr_availability_replica_states hars 
            INNER JOIN sys.availability_groups ag ON ag.group_id = hars.group_id 
            INNER JOIN sys.availability_replicas ar ON ar.replica_id = hars.replica_id
           
)  

SET @PRIMCount =
(
SELECT COUNT(*) as PRIMARY_COMPUTE
            FROM sys.dm_hadr_availability_replica_states hars 
            INNER JOIN sys.availability_groups ag ON ag.group_id = hars.group_id 
            INNER JOIN sys.availability_replicas ar ON ar.replica_id = hars.replica_id
            WHERE role_desc = ''PRIMARY''
)         

if @PRIMCount = 1 or @CHECHAVG=0
BEGIN

SELECT [name],date_created,date_modified 
INTO #JOBS
FROM msdb.dbo.sysjobs
WHERE name <> ''syspolicy_purge_history''

use admindb

	SET @countsql=
	(
	select count(*) from #JOBS
	)

WHILE  @countsql >=1
	BEGIN


		SET @JobName = 
		(
		SELECT TOP 1 [name] from #JOBS
		)

		--select @JobName

SELECT
    @job_id = job_id,
    @enabled = [enabled],
    @notify_level_eventlog = notify_level_eventlog,
    @notify_level_email = notify_level_email,
    @notify_level_netsend = notify_level_netsend,
    @notify_level_page = notify_level_page,
    @delete_level = delete_level,
    @description = [description],
    @category_name = c.name,
    @owner_login_name = o.name
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.syscategories c ON c.category_id = j.category_id
INNER JOIN msdb.dbo.syslogins o ON j.owner_sid = o.sid
WHERE j.name = @JobName

SET @SQL = N''USE msdb
DECLARE @jobId BINARY(16)
DECLARE @ReturnCode INT

EXEC @ReturnCode =  msdb.dbo.sp_add_job
    @job_name=N'''''' + @JobName + '''''', 
    @enabled='' + CAST(@enabled AS NVARCHAR(1)) + '', 
    @notify_level_eventlog='' + CAST(@notify_level_eventlog AS NVARCHAR(5)) + '', 
    @notify_level_email='' + CAST(@notify_level_email AS NVARCHAR(5)) + '', 
    @notify_level_netsend='' + CAST(@notify_level_netsend AS NVARCHAR(5)) + '', 
    @notify_level_page='' + CAST(@notify_level_page AS NVARCHAR(5)) + '', 
    @delete_level='' + CAST(@delete_level AS NVARCHAR(5)) + '', 
    @description=N'''''' + @description + '''''', 
    @category_name=N'''''' + @category_name + '''''', 
    @owner_login_name=N'''''' + @owner_login_name + '''''',
    @job_id = @jobId OUTPUT
''

DECLARE JOB_STEPS CURSOR FOR
SELECT
    step_id,
    step_name,
    command,
    additional_parameters,
    cmdexec_success_code,
    on_success_action,
    on_success_step_id,
    on_fail_action,
    on_fail_step_id,
    retry_attempts,
    retry_interval,
    os_run_priority,
    subsystem,
    [server],
    database_name,
    flags,
    p.name,
    output_file_name
FROM msdb.dbo.sysjobsteps s
LEFT JOIN msdb.dbo.sysproxies p ON p.proxy_id = s.proxy_id
WHERE job_id=@job_id
ORDER BY step_id

OPEN JOB_STEPS
FETCH NEXT FROM JOB_STEPS
    INTO @step_id,
         @step_name,
         @command,
         @additional_parameters,
         @cmdexec_success_code,
         @on_success_action,
         @on_success_step_id,
         @on_fail_action,
         @on_fail_step_id,
         @retry_attempts,
         @retry_interval,
         @os_run_priority,
         @subsystem,
         @server,
         @database_name,
         @flags,
         @proxy_name,
         @output_file_name

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = @SQL + ''
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep
    @job_id=@jobId,
    @step_name=N'''''' + @step_name + '''''', 
    @command=N'''''' + REPLACE(ISNULL(@command,''''),'''''''','''''''''''') + '''''',
    @additional_parameters=N'''''' + ISNULL(@additional_parameters,'''') + '''''',
    @step_id='' + CAST(@step_id AS NVARCHAR(5)) + '', 
    @cmdexec_success_code='' + CAST(@cmdexec_success_code AS NVARCHAR(5)) + '', 
    @on_success_action='' + CAST(@on_success_action AS NVARCHAR(5)) + '', 
    @on_success_step_id='' + CAST(@on_success_step_id AS NVARCHAR(5)) + '', 
    @on_fail_action='' + CAST(@on_fail_action AS NVARCHAR(5)) + '', 
    @on_fail_step_id='' + CAST(@on_fail_step_id AS NVARCHAR(5)) + '', 
    @retry_attempts='' + CAST(@retry_attempts AS NVARCHAR(5)) + '', 
    @retry_interval='' + CAST(@retry_interval AS NVARCHAR(5)) + '', 
    @os_run_priority='' + CAST(@os_run_priority AS NVARCHAR(5)) + '',
    @subsystem=N'''''' + ISNULL(@subsystem,'''') + '''''', 
    @server=N'''''' + ISNULL(@server,'''') + '''''', 
    @database_name=N'''''' + ISNULL(@database_name,'''') + '''''', 
    @flags='' + CAST(@flags AS NVARCHAR(5)) + '',
    @proxy_name='''''' + ISNULL(@proxy_name,'''') + '''''', 
    @output_file_name=N'''''' + ISNULL(@output_file_name,'''') + ''''''
    ''

    FETCH NEXT FROM JOB_STEPS
    INTO @step_id,
         @step_name,
         @command,
         @additional_parameters,
         @cmdexec_success_code,
         @on_success_action,
         @on_success_step_id,
         @on_fail_action,
         @on_fail_step_id,
         @retry_attempts,
         @retry_interval,
         @os_run_priority,
         @subsystem,
         @server,
         @database_name,
         @flags,
         @proxy_name,
         @output_file_name
END

CLOSE JOB_STEPS
DEALLOCATE JOB_STEPS

SET @date_created=
(
SELECT date_created from #jobs 
where [name] = @JobName
)

SET @date_modified=
(
SELECT date_modified from #jobs 
where [name] = @JobName
)

INSERT INTO [helper].[HistAgentJobs](
		[timestamp],
        [job_name],
		[job_definition],
        [deployment_type]
) VALUES (
	GETDATE(),
	@JobName,
	@SQL,
	''START''
)

		delete from #JOBS where [name] = @JobName
		SET @countsql = @countsql -1

 END

	drop table #JOBS
END
'                                              );

EXEC sp_executesql @sqlstate_Agent;

UPDATE helper.HistAgentJobs SET deployment_id = @deployment_id WHERE deployment_id IS NULL;

    -- Linked Servers

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistLinkedServers'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistLinkedServers]
        (
            [timestamp] [DATETIME] NOT NULL,
            [server_name] [NVARCHAR](1000) NOT NULL,
            [object_definition] [NVARCHAR](MAX) NULL,
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL
        );
    END;

    CREATE TABLE #LSTemp
    (
        [srv_name] [NVARCHAR](2000) NULL,
        [srv_providername] [NVARCHAR](2000) NULL,
        [srv_product] [NVARCHAR](2000) NULL,
        [srv_datasource] [NVARCHAR](MAX) NULL,
        [srv_providerstring] [NVARCHAR](MAX) NULL,
        [srv_location] [NVARCHAR](2000) NULL,
        [srv_cat] [NVARCHAR](2000) NULL
    );

    -- Execute proc to retrieve linked servers present on the system
    INSERT INTO #LSTemp
    (
        [srv_name],
        [srv_providername],
        [srv_product],
        [srv_datasource],
        [srv_providerstring],
        [srv_location],
        [srv_cat]
    )
    EXEC sys.sp_linkedservers;

    DECLARE @srv_name NVARCHAR(1000);
    DECLARE @srv_providername NVARCHAR(1000);
    DECLARE @srv_product NVARCHAR(1000);
    DECLARE @srv_datasource NVARCHAR(1000);
    DECLARE @srv_providerstring NVARCHAR(1000);
    DECLARE @srv_location NVARCHAR(1000);
    DECLARE @srv_cat NVARCHAR(1000);
    DECLARE @definition NVARCHAR(MAX);

    -- Build linked server create statements from temp tab
    WHILE (EXISTS (SELECT * FROM #LSTemp))
    BEGIN

        SELECT TOP (1)
               @srv_name = [srv_name]
        FROM #LSTemp
        ORDER BY [srv_name];

        SELECT TOP (1)
               @srv_providername = [srv_providername]
        FROM #LSTemp
        WHERE [srv_name] = @srv_name
        ORDER BY [srv_name];
        SELECT TOP (1)
               @srv_product = [srv_product]
        FROM #LSTemp
        WHERE [srv_name] = @srv_name
        ORDER BY [srv_name];
        SELECT TOP (1)
               @srv_datasource = [srv_datasource]
        FROM #LSTemp
        WHERE [srv_name] = @srv_name
        ORDER BY [srv_name];
        SELECT TOP (1)
               @srv_providerstring = [srv_providerstring]
        FROM #LSTemp
        WHERE [srv_name] = @srv_name
        ORDER BY [srv_name];
        SELECT TOP (1)
               @srv_location = [srv_location]
        FROM #LSTemp
        WHERE [srv_name] = @srv_name
        ORDER BY [srv_name];
        SELECT TOP (1)
               @srv_cat = [srv_cat]
        FROM #LSTemp
        WHERE [srv_name] = @srv_name
        ORDER BY [srv_name];

        SET @definition = N'EXEC sp_addlinkedserver @server=''' + @srv_name + N'''';

        IF (@srv_product IS NOT NULL)
        BEGIN
            SET @definition = @definition + N', @srvproduct=''' + @srv_product + N'''';
        END;

        IF (@srv_providername IS NOT NULL)
        BEGIN
            SET @definition = @definition + N', @provider=''' + @srv_providername + N'''';
        END;

        IF (@srv_datasource IS NOT NULL)
        BEGIN
            SET @definition = @definition + N', @datasrc=''' + @srv_datasource + N'''';
        END;

        IF (@srv_location IS NOT NULL)
        BEGIN
            SET @definition = @definition + N', @location=''' + @srv_location + N'''';
        END;

        IF (@srv_providerstring IS NOT NULL)
        BEGIN
            SET @definition = @definition + N', @provstr=''' + @srv_providerstring + N'''';
        END;

        IF (@srv_cat IS NOT NULL)
        BEGIN
            SET @definition = @definition + N', @catalog=''' + @srv_cat + N'''';
        END;

        INSERT INTO [helper].[HistLinkedServers]
        (
            [timestamp],
            [server_name],
            [object_definition],
            [deployment_type],
            [deployment_id]
        )
        SELECT GETDATE(),
               @srv_name,
               @definition,
               'START',
               @deployment_id;

        DELETE #LSTemp
        WHERE [srv_name] = @srv_name;
    END;

    -- Views, procs, funcs

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistViews'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistViews]
        (
            [timestamp] [DATETIME] NOT NULL,
            [view_name] [NVARCHAR](1000) NOT NULL,
            [schema_name] [NVARCHAR](1000) NOT NULL,
            [object_definition] [NVARCHAR](MAX) NULL,
            [database_name] [NVARCHAR](1000) NOT NULL,
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL
        );
    END;

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistProcedures'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistProcedures]
        (
            [timestamp] [DATETIME] NOT NULL,
            [procedure_name] [NVARCHAR](1000) NOT NULL,
            [schema_name] [NVARCHAR](1000) NOT NULL,
            [object_definition] [NVARCHAR](MAX) NULL,
            [database_name] [NVARCHAR](1000) NOT NULL,
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL
        );
    END;

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistFunctions'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistFunctions]
        (
            [timestamp] [DATETIME] NOT NULL,
            [function_name] [NVARCHAR](1000) NOT NULL,
            [schema_name] [NVARCHAR](1000) NOT NULL,
            [object_definition] [NVARCHAR](MAX) NULL,
            [database_name] [NVARCHAR](1000) NOT NULL,
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL
        );
    END;

    DECLARE @db NVARCHAR(1000);

    SELECT [name]
    INTO #dbs
    FROM sys.databases
    WHERE [database_id] NOT IN ( 1, 2, 3, 4 )
          AND [name] NOT IN ( 'DWConfiguration', 'DWDiagnostics', 'DWQueue' );

    -- temp tabs for loop
    CREATE TABLE #views_temp
    (
        [name] [NVARCHAR](1000) NOT NULL,
        [schema_name] [NVARCHAR](1000) NOT NULL,
        [database_name] [NVARCHAR](1000) NOT NULL,
        [definition] [NVARCHAR](MAX) NULL
    );

    CREATE TABLE #procs_temp
    (
        [name] [NVARCHAR](1000) NOT NULL,
        [schema_name] [NVARCHAR](1000) NOT NULL,
        [database_name] [NVARCHAR](1000) NOT NULL,
        [definition] [NVARCHAR](MAX) NULL
    );

    CREATE TABLE #funcs_temp
    (
        [name] [NVARCHAR](1000) NOT NULL,
        [schema_name] [NVARCHAR](1000) NOT NULL,
        [database_name] [NVARCHAR](1000) NOT NULL,
        [definition] [NVARCHAR](MAX) NULL
    );

    WHILE (EXISTS (SELECT * FROM #dbs))
    BEGIN

        SELECT TOP (1)
               @db = [name]
        FROM #dbs
        ORDER BY [name] ASC;

        -- views

        SET @stringToExecute
            = N'Use ' + QUOTENAME(@db)
              + N'
		
		SELECT [name], SCHEMA_NAME(schema_id), DB_NAME(parent_object_id), OBJECT_DEFINITION(object_id) FROM sys.views';

        INSERT INTO #views_temp
        EXEC sp_executesql @stringToExecute;

        -- procs

        SET @stringToExecute
            = N'Use ' + QUOTENAME(@db)
              + N'
		
		SELECT [name], SCHEMA_NAME(schema_id), DB_NAME(parent_object_id), OBJECT_DEFINITION(object_id) FROM sys.procedures';

        INSERT INTO #procs_temp
        EXEC sp_executesql @stringToExecute;

        -- functions

        SET @stringToExecute
            = N'Use ' + QUOTENAME(@db)
              + N'
		
		SELECT [name], SCHEMA_NAME(schema_id), DB_NAME(parent_object_id), [definition] FROM sys.sql_modules m INNER JOIN sys.objects o ON m.object_id = o.object_id WHERE type_desc LIKE ''%function%''';

        INSERT INTO #funcs_temp
        EXEC sp_executesql @stringToExecute;

        DELETE #dbs
        WHERE [name] = @db;
    END;

    -- parse views from temp tab
    INSERT INTO [helper].[HistViews]
    (
        [timestamp],
        [view_name],
        [schema_name],
        [object_definition],
        [database_name],
        [deployment_type],
        [deployment_id]
    )
    SELECT GETDATE(),
           [name],
           [schema_name],
           [definition],
           [database_name],
           'START',
           @deployment_id
    FROM #views_temp;

    -- parse procs from temp tab
    INSERT INTO [helper].[HistProcedures]
    (
        [timestamp],
        [procedure_name],
        [schema_name],
        [object_definition],
        [database_name],
        [deployment_type],
        [deployment_id]
    )
    SELECT GETDATE(),
           [name],
           [schema_name],
           [definition],
           [database_name],
           'START',
           @deployment_id
    FROM #procs_temp;

    -- prase functions from temp tab
    INSERT INTO [helper].[HistFunctions]
    (
        [timestamp],
        [function_name],
        [schema_name],
        [object_definition],
        [database_name],
        [deployment_type],
        [deployment_id]
    )
    SELECT GETDATE(),
           [name],
           [schema_name],
           [definition],
           [database_name],
           'START',
           @deployment_id
    FROM #funcs_temp;

    ---- Tables

    IF (NOT EXISTS
    (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'helper'
              AND TABLE_NAME = 'HistTables'
    )
       )
    BEGIN
        CREATE TABLE [helper].[HistTables]
        (
            [timestamp] [DATETIME] NOT NULL,
            [schema_name] [NVARCHAR](1000) NOT NULL,
            [table_name] [NVARCHAR](1000) NOT NULL,
            [database_name] [NVARCHAR](1000) NOT NULL,
            [definition] [NVARCHAR](MAX) NULL,
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL
        );
    END;

    DECLARE @object_name NVARCHAR(2000);

    CREATE TABLE #tmp_tables
    (
        [id] [INT] IDENTITY(1, 1) NOT NULL,
        [database_name] [NVARCHAR](1000) NOT NULL,
        [schema_name] [NVARCHAR](1000) NOT NULL,
        [table_name] [NVARCHAR](1000) NOT NULL
    );

    DECLARE @sql NVARCHAR(MAX);

    SELECT @sql
        =
    (
        SELECT ' UNION ALL
        SELECT ' + +QUOTENAME(name, '''')
               + ' as database_name,
               s.name COLLATE DATABASE_DEFAULT
                    AS schema_name,
               t.name COLLATE DATABASE_DEFAULT as table_name 
               FROM ' + QUOTENAME(name) + '.sys.tables t
               JOIN ' + QUOTENAME(name) + '.sys.schemas s
                    on s.schema_id = t.schema_id'
        FROM sys.databases
        WHERE state = 0
              AND name <> 'tempdb'
              AND name <> 'msdb'
              AND name <> 'DWConfiguration'
              AND name <> 'DWDiagnostics'
              AND name <> 'DWQueue'
              AND name <> 'master'
              AND name <> 'model'
        ORDER BY [name]
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)');

    SET @sql
        = STUFF(@sql, 1, 12, '')
          + N' order by database_name, 
                                               schema_name,
                                               table_name';

    INSERT INTO #tmp_tables
    (
        [database_name],
        [schema_name],
        [table_name]
    )
    EXECUTE (@sql);


    CREATE TABLE #tmp_tables2
    (
        [id] [INT] IDENTITY(1, 1) NOT NULL,
        [schema_name] [NVARCHAR](1000) NOT NULL,
        [table_name] [NVARCHAR](1000) NOT NULL,
        [definition] [NVARCHAR](MAX) NOT NULL,
        [database_name] [NVARCHAR](1000) NOT NULL
    );

    DECLARE @id INT;
    DECLARE @database_name NVARCHAR(1000);
    DECLARE @schema_name NVARCHAR(1000);
    DECLARE @table_name NVARCHAR(1000);

    WHILE EXISTS (SELECT * FROM #tmp_tables)
    BEGIN

        SELECT TOP (1)
               @id = [id]
        FROM #tmp_tables
        ORDER BY [id] ASC;

        SELECT TOP (1)
               @database_name = [database_name]
        FROM #tmp_tables
        WHERE [id] = @id
        ORDER BY [id];

        SELECT TOP (1)
               @schema_name = [schema_name]
        FROM #tmp_tables
        WHERE [id] = @id
        ORDER BY [id];

        SELECT TOP (1)
               @table_name = [table_name]
        FROM #tmp_tables
        WHERE [id] = @id
        ORDER BY [id];

        SET @object_name = N'[' + @database_name + N'].[' + @schema_name + N'].[' + @table_name + N']';

		SET @sql = 'Use ' + @database_name + '

		EXEC dbo.sp_GetDDL ''' + @object_name + ''';'

        INSERT INTO #tmp_tables2
        (
            [schema_name],
            [table_name],
            [definition],
            [database_name]
        )
		EXEC sp_executesql @sql
        --EXEC dbo.sp_GetDDL @object_name;

        DELETE #tmp_tables
        WHERE [id] = @id;

        SELECT TOP (1)
               @id = MAX(id)
        FROM #tmp_tables2;

        UPDATE #tmp_tables2
        SET [database_name] = @database_name
        WHERE [id] = @id;
    END;

    INSERT INTO [helper].[HistTables]
    (
        [timestamp],
        [schema_name],
        [table_name],
        [database_name],
        [definition],
        [deployment_type],
        [deployment_id]
    )
    SELECT GETDATE(),
           [schema_name],
           [table_name],
           [database_name],
           [definition],
           'START',
           @deployment_id
    FROM #tmp_tables2;

    SELECT 'Prozedur gestartet.' AS [Status],
           ORIGINAL_LOGIN() AS [Started by],
           @deployment_id AS [Deployment Id],
           'EXEC helper.sp_hist_stop @deploymentId = ''' + CONVERT(NVARCHAR(MAX), @deployment_id) + ''', @debug = 0' AS [Stop Procedure Statement];

END;
GO
