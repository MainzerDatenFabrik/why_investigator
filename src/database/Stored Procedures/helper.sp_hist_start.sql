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

    DECLARE login_cursor CURSOR FOR(
    SELECT DISTINCT
           l.sid,
           l.name,
           p.type,
           p.is_disabled,
           p.default_database_name,
           l.hasaccess,
           l.denylogin
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
         @denylogin;
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
                 @denylogin;
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
            [deployment_type] [NVARCHAR](1000) NOT NULL,
            [deployment_id] UNIQUEIDENTIFIER NOT NULL
        );
    END;

    -- Store the name of all agent jobs currently present on the system in the table
    INSERT INTO [helper].[HistAgentJobs]
    (
        [timestamp],
        [job_name],
        [deployment_type],
        [deployment_id]
    )
    SELECT GETDATE(),
           [name],
           'START',
           @deployment_id
    FROM msdb.dbo.sysjobs;

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

        INSERT INTO #tmp_tables2
        (
            [schema_name],
            [table_name],
            [definition],
            [database_name]
        )
        EXEC dbo.sp_GetDDL @object_name;

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
