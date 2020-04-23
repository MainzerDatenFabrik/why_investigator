SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [helper].[sp_hist_stop]
AS
BEGIN

DECLARE @deployment_id UNIQUEIDENTIFIER

SET @deployment_id = (SELECT deployment_id FROM [helper].[HistDeploymentId] WHERE id = (SELECT MAX(id) FROM [helper].[HistDeploymentId]))

-- databases
INSERT INTO [helper].[HistDatabases] ([timestamp], [database_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], 'ENDE', @deployment_id FROM sys.databases WHERE [database_id] NOT IN (1, 2, 3, 4);

--logins
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @type varchar (1)
DECLARE @is_disabled int
DECLARE @defaultdb sysname
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @tmpstr  varchar (1024)
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)
DECLARE @stringToExecute nvarchar(MAX)
DECLARE @name NVARCHAR(2000)

DECLARE login_cursor CURSOR FOR
(SELECT DISTINCT l.sid, l.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM sys.syslogins l LEFT JOIN sys.server_principals p ON (l.name = p.name) WHERE p.type IN ('S', 'G', 'U') AND l.name <> 'sa') OPEN login_cursor

FETCH NEXT FROM login_cursor INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
if(@@fetch_status = -1)
BEGIN
	PRINT 'Exception occurred while retrieving login cursor.'
END
WHILE(@@fetch_status <> -1)
BEGIN
	if(@@fetch_status <> -2)
	BEGIN
		if(@type IN ('G', 'U'))
		BEGIN
			SET @tmpstr = 'CREATE LOGIN ' + @name + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']' 
		END
		ELSE BEGIN
			
			SET @PWD_varbinary = CAST(LOGINPROPERTY(@name, 'PasswordHash') AS varbinary (256));
			EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT;
			EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT;

			SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
			SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name

			SET @tmpstr = 'CREATE LOGIN ' + @name + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

			IF ( @is_policy_checked IS NOT NULL )
			BEGIN
				SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
			END
			IF ( @is_expiration_checked IS NOT NULL )
			BEGIN
				SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
			END
		END

		if(@denylogin = 1)
		BEGIN
			SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ''' + @name + ''' '
		END
		ELSE IF(@hasaccess = 0)
		BEGIN
			SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ''' + @name + ''' '
		END

		if(@is_disabled = 1)
		BEGIN
			SET @tmpstr = @tmpstr + '; ALTER LOGIN ''' + @name + ''' DISABLE'
		END

		INSERT INTO [helper].[HistLogins](
			[timestamp], 
			[login_name], 
			[object_definition], 
			[deployment_type], 
			[deployment_id]
		) 
		SELECT 
			GETDATE(),
			@name,
			@tmpstr,
			'START',
			@deployment_id

	FETCH NEXT FROM login_cursor INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
	END
END
CLOSE login_cursor
DEALLOCATE login_cursor

--INSERT INTO [helper].[HistLogins] ([timestamp], [login_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [loginname], 'ENDE', @deployment_id FROM sys.syslogins;

--jobs
INSERT INTO [helper].[HistAgentJobs] ([timestamp], [job_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], 'ENDE', @deployment_id FROM msdb.dbo.sysjobs;

--linked server
CREATE TABLE #LSTemp(
	[srv_name] [nvarchar](2000)  NULL,
	[srv_providername] [nvarchar](2000)  NULL,
	[srv_product] [nvarchar](2000)  NULL,
	[srv_datasource] [nvarchar](MAX)  NULL,
	[srv_providerstring] [nvarchar](MAX)  NULL,
	[srv_location] [nvarchar](2000)  NULL,
	[srv_cat] [nvarchar](2000)  NULL
)

INSERT INTO #LSTemp(
	[srv_name], 
	[srv_providername], 
	[srv_product], 
	[srv_datasource], 
	[srv_providerstring], 
	[srv_location], 
	[srv_cat]
) 
EXEC sys.sp_linkedservers;

INSERT INTO [helper].[HistLinkedServers](
[timestamp], 
[server_name],
[object_definition],
[deployment_type], 
[deployment_id]
) 
SELECT 
	GETDATE(), 
	[srv_name], 
	('EXEC sp_addlinkedserver @server=''' + [srv_name] + ''', @srvproduct=''' + [srv_product] + ''', @provider=''' + [srv_providername] + ''', @datasrc=''' +
		[srv_datasource] + ''''),
	'ENDE', 
	@deployment_id 
FROM #LSTemp;

--views
INSERT INTO [helper].[HistViews]([timestamp], [view_name], [schema_name], [object_definition], [database_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], SCHEMA_NAME(SCHEMA_ID), OBJECT_DEFINITION(object_id), DB_NAME(parent_object_id), 'ENDE', @deployment_id FROM sys.views;

--procs
INSERT INTO [helper].[HistProcedures]([timestamp], [procedure_name], [schema_name], [object_definition], [database_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], SCHEMA_NAME(SCHEMA_ID), OBJECT_DEFINITION(object_id), DB_NAME(parent_object_id), 'ENDE', @deployment_id FROM sys.procedures;

--funcs
INSERT INTO [helper].[HistFunctions]([timestamp], [function_name], [schema_name], [object_definition], [database_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], SCHEMA_NAME(SCHEMA_ID), [definition], DB_NAME(o.parent_object_id), 'ENDE', @deployment_id FROM sys.sql_modules m INNER JOIN sys.objects o ON m.[object_id] = o.[object_id] WHERE o.[type_desc] LIKE '%function%';

--tabs
--INSERT INTO [helper].[HistTables]([timestamp], [table_name], [schema_name], [database_name], [deployment_type], [deployment_id])
--SELECT GETDATE(), [name], SCHEMA_NAME(SCHEMA_ID), DB_NAME(parent_object_id), 'ENDE', @deployment_id
--FROM sys.tables

CREATE TABLE #Temp2(
	[schema_name] [NVARCHAR](1000) NOT NULL,
	[table_name] [NVARCHAR](1000) NOT NULL,
	[definition] [NVARCHAR](MAX) NOT NULL,
	[database_name] [NVARCHAR](1000) NOT NULL
)

DECLARE @table NVARCHAR(1000)
DECLARE @schema NVARCHAR(1000)
DECLARE @object_name NVARCHAR(2000)

DECLARE table_cursor CURSOR FOR
(SELECT [name], SCHEMA_NAME(SCHEMA_ID) FROM sys.tables) OPEN table_cursor

FETCH NEXT FROM table_cursor INTO @table, @schema
WHILE(@@FETCH_STATUS <> -1)
BEGIN
	IF(@@FETCH_STATUS <> -2)
	BEGIN

	SET @object_name = @schema + '.' + @table

	INSERT INTO #Temp2([schema_name], [table_name], [definition], [database_name]) EXEC dbo.sp_GetDDL @object_name

	FETCH NEXT FROM table_cursor INTO @table, @schema
	END
END
CLOSE table_cursor
DEALLOCATE table_cursor

INSERT INTO [helper].[HistTables]([timestamp], [schema_name], [table_name], [database_name], [definition], [deployment_type], [deployment_id])
SELECT GETDATE(), schema_name, table_name, database_name, definition, 'ENDE', @deployment_id FROM #Temp2

--

-- create delta table from all objects (entries are objects that have been modified)

-- DROP TABLE #TempDelta

CREATE TABLE #TempDelta(
	[id] [INT] IDENTITY(1,1) NOT NULL,
	[schema_name] [NVARCHAR](1000) NULL,
	[object_name] [NVARCHAR](1000) NOT NULL,
	[object_type] [NVARCHAR](1000) NOT NULL,
	[database_name] [NVARCHAR](1000) NOT NULL,
	[object_definition] [NVARCHAR](MAX) NOT NULL,
	[object_definition_count] [INT] NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL,
	[deployment_type_count] [INT] NOT NULL
)

-- tables
SELECT 
	[schema_name], 
	[table_name] AS [object_name],
	'TABLE' AS [object_type],
	[database_name], 
	[definition], 
	COUNT([definition]) AS [definition_count], 
	[deployment_id], 
	COUNT(deployment_type) AS [deploy_type_count]
INTO #TempTables
FROM [helper].[HistTables]
GROUP BY 
	[schema_name],
	[table_name],
	[database_name],
	[deployment_id],
	[definition]

SELECT * FROM #TempTables

INSERT INTO #TempDelta(
	[schema_name],
	[object_name],
	[object_type],
	[database_name],
	[object_definition],
	[object_definition_count],
	[deployment_id],
	[deployment_type_count]
)
SELECT 
[t].[schema_name],
[t].[object_name],
[t].[object_type],
[t].[database_name],
[t].[definition],
[t].[definition_count],
[t].[deployment_id],
[t].[deploy_type_count]
FROM #TempTables [t]
	INNER JOIN [helper].[HistTables] [h]
		ON [h].[definition] = [t].[definition]
			AND [h].[deployment_id] = [t].[deployment_id]
WHERE [t].[definition_count] = 1 
	AND [h].[deployment_type] = 'START'

-- views
SELECT
	[schema_name],
	[view_name] AS [object_name],
	'VIEW' AS [object_type],
	[database_name],
	[object_definition],
	COUNT([object_definition]) AS [definition_count], 
	[deployment_id], 
	COUNT(deployment_type) AS [deploy_type_count]
INTO #TempViews
FROM [helper].[HistViews]
GROUP BY 
	[schema_name],
	[view_name],
	[database_name],
	[deployment_id],
	[object_definition]

SELECT * FROM #TempViews

INSERT INTO #TempDelta(
	[schema_name],
	[object_name],
	[object_type],
	[database_name],
	[object_definition],
	[object_definition_count],
	[deployment_id],
	[deployment_type_count]
)
SELECT 
[t].[schema_name],
[t].[object_name],
[t].[object_type],
[t].[database_name],
[t].[object_definition],
[t].[definition_count],
[t].[deployment_id],
[t].[deploy_type_count]
FROM #TempViews [t]
	INNER JOIN [helper].[HistViews] [h]
		ON [h].[object_definition] = [t].[object_definition]
			AND [h].[deployment_id] = [t].[deployment_id]
WHERE [t].[definition_count] = 1 
	AND [h].[deployment_type] = 'START'

-- procedures
SELECT
	[schema_name],
	[procedure_name] AS [object_name],
	'PROCEDURE' AS [object_type],
	[database_name],
	[object_definition],
	COUNT([object_definition]) AS [definition_count], 
	[deployment_id], 
	COUNT(deployment_type) AS [deploy_type_count]
INTO #TempProcedures
FROM [helper].[HistProcedures]
GROUP BY 
	[schema_name],
	[procedure_name],
	[database_name],
	[deployment_id],
	[object_definition]

SELECT * FROM #TempProcedures

INSERT INTO #TempDelta(
	[schema_name],
	[object_name],
	[object_type],
	[database_name],
	[object_definition],
	[object_definition_count],
	[deployment_id],
	[deployment_type_count]
)
SELECT 
[t].[schema_name],
[t].[object_name],
[t].[object_type],
[t].[database_name],
[t].[object_definition],
[t].[definition_count],
[t].[deployment_id],
[t].[deploy_type_count]
FROM #TempProcedures [t]
	INNER JOIN [helper].[HistProcedures] [h]
		ON [h].[object_definition] = [t].[object_definition]
			AND [h].[deployment_id] = [t].[deployment_id]
WHERE [t].[definition_count] = 1 
	AND [h].[deployment_type] = 'START'

-- functions
SELECT
	[schema_name],
	[function_name] AS [object_name],
	'FUNCTION' AS [object_type],
	[database_name],
	[object_definition],
	COUNT([object_definition]) AS [definition_count], 
	[deployment_id], 
	COUNT(deployment_type) AS [deploy_type_count]
INTO #TempFunctions
FROM [helper].[HistFunctions]
GROUP BY 
	[schema_name],
	[function_name],
	[database_name],
	[deployment_id],
	[object_definition]

SELECT * FROM #TempFunctions

INSERT INTO #TempDelta(
	[schema_name],
	[object_name],
	[object_type],
	[database_name],
	[object_definition],
	[object_definition_count],
	[deployment_id],
	[deployment_type_count]
)
SELECT 
[t].[schema_name],
[t].[object_name],
[t].[object_type],
[t].[database_name],
[t].[object_definition],
[t].[definition_count],
[t].[deployment_id],
[t].[deploy_type_count]
FROM #TempFunctions [t]
	INNER JOIN [helper].[HistFunctions] [h]
		ON [h].[object_definition] = [t].[object_definition]
			AND [h].[deployment_id] = [t].[deployment_id]
WHERE [t].[definition_count] = 1 
	AND [h].[deployment_type] = 'START'

-- linked servers
SELECT
	'' AS [schema_name],
	[server_name] AS [object_name],
	'LINKED SERVER' AS [object_type],
	'' AS [database_name],
	[object_definition],
	COUNT([object_definition]) AS [definition_count], 
	[deployment_id], 
	COUNT(deployment_type) AS [deploy_type_count]
INTO #TempLinkedServers
FROM [helper].[HistLinkedServers]
GROUP BY 
	[server_name],
	[deployment_id],
	[object_definition]

SELECT * FROM #TempLinkedServers

INSERT INTO #TempDelta(
	[schema_name],
	[object_name],
	[object_type],
	[database_name],
	[object_definition],
	[object_definition_count],
	[deployment_id],
	[deployment_type_count]
)
SELECT 
[t].[schema_name],
[t].[object_name],
[t].[object_type],
[t].[database_name],
[t].[object_definition],
[t].[definition_count],
[t].[deployment_id],
[t].[deploy_type_count]
FROM #TempLinkedServers [t]
	INNER JOIN [helper].[HistLinkedServers] [h]
		ON [h].[object_definition] = [t].[object_definition]
			AND [h].[deployment_id] = [t].[deployment_id]
WHERE [t].[definition_count] = 1 
	AND [h].[deployment_type] = 'START'

-- logins
SELECT
	'' AS [schema_name],
	[login_name] AS [object_name],
	'LOGIN' AS [object_type],
	'' AS [database_name],
	[object_definition],
	COUNT([object_definition]) AS [definition_count], 
	[deployment_id], 
	COUNT(deployment_type) AS [deploy_type_count]
INTO #TempLogins
FROM [helper].[HistLogins]
GROUP BY 
	[login_name],
	[deployment_id],
	[object_definition]

SELECT * FROM #TempLogins

INSERT INTO #TempDelta(
	[schema_name],
	[object_name],
	[object_type],
	[database_name],
	[object_definition],
	[object_definition_count],
	[deployment_id],
	[deployment_type_count]
)
SELECT 
[t].[schema_name],
[t].[object_name],
[t].[object_type],
[t].[database_name],
[t].[object_definition],
[t].[definition_count],
[t].[deployment_id],
[t].[deploy_type_count]
FROM #TempLogins [t]
	INNER JOIN [helper].[HistLogins] [h]
		ON [h].[object_definition] = [t].[object_definition]
			AND [h].[deployment_id] = [t].[deployment_id]
WHERE [t].[definition_count] = 1 
	AND [h].[deployment_type] = 'START'

SELECT * FROM #TempDelta;

-- process delta table entries

DECLARE @id INT
--DECLARE @object_name NVARCHAR(1000)
DECLARE @object_type NVARCHAR(1000)
DECLARE @object_definition NVARCHAR(1000)

WHILE EXISTS(SELECT * FROM #TempDelta)
BEGIN

	SELECT TOP(1) @id = id FROM #TempDelta ORDER BY id ASC

	-- the name of the object
	SELECT TOP(1) @object_name = [object_name] FROM #TempDelta WHERE id = @id ORDER BY id ASC

	-- the type of the object
	SELECT TOP(1) @object_type = [object_type] FROM #TempDelta WHERE id = @id ORDER BY id ASC

	-- the definition of the object
	SELECT TOP(1) @object_definition = [object_definition] FROM #TempDelta WHERE id = @id ORDER BY id ASC

	IF(@object_type = 'TABLE')
	BEGIN
		PRINT 'Reverting changes made to table ' + @object_name
		EXEC sp_executesql @object_definition
	END
	ELSE IF(@object_type = 'VIEW')
	BEGIN
		PRINT 'Reverting changes made to view ' + @object_name

		SET @stringToExecute = 'IF EXISTS(SELECT * FROM sys.views WHERE [name] = ''' + @object_name + ''')
			BEGIN
				DROP VIEW ' + @object_name + '
			END'
		EXEC sp_executesql @stringToExecute
		EXEC sp_executesql @object_definition
	END
	ELSE IF(@object_type = 'PROCEDURE')
	BEGIN 
		PRINT 'Reverting changes made to procedure ' + @object_name 

		SET @stringToExecute = 'IF EXISTS(SELECT * FROM sys.procedures WHERE [name] = ''' + @object_name + ''')
			BEGIN
				DROP PROCEDURE ' + @object_name + '
			END'
		EXEC sp_executesql @stringToExecute
		EXEC sp_executesql @object_definition
	END
	ELSE IF(@object_type = 'FUNCTION')
	BEGIN 
		PRINT 'Reverting changes made to function ' + @object_name

		SET @stringToExecute = 'IF EXISTS(SELECT * FROM FROM sys.sql_modules m INNER JOIN sys.objects o ON m.[object_id] = o.[object_id] WHERE o.[type_desc] LIKE ''%function%'' AND [name] =''' + @object_name + ''')
			BEGIN
				DROP FUNCTION ' + @object_name + '
			END'
		EXEC sp_executesql @stringToExecute
		EXEC sp_executesql @object_definition
	END
	ELSE IF(@object_type = 'LINKED SERVER')
	BEGIN 
		PRINT 'Reverting changes made to linked server ' + @object_name

		SET @stringToExecute = 'IF EXISTS(SELECT * FROM sys.servers WHERE name = ''' + @object_name + ''')
			BEGIN
				EXEC sp_dropserver ''' + @object_name + '''
			END'
		EXEC sp_executesql @stringToExecute
		EXEC sp_executesql @object_definition

	END
	ELSE IF(@object_type = 'LOGIN')
	BEGIN 
		PRINT 'Reverting changes made to login ' + @object_name
		
		SET @stringToExecute = 'IF EXISTS(SELECT loginname FROM sys.syslogins WHERE [name] = ''' + @object_name + ''')
			BEGIN
			DROP LOGIN ' + @object_name + '
			END'
		EXEC sp_executesql @stringToExecute
		EXEC sp_executesql @object_definition
	END

	DELETE #TempDelta WHERE id = @id
END

-- Drop all newly created objects 

-- tables
SELECT
	[name]
INTO #temp_tabs
FROM sys.tables
WHERE [name] NOT IN (SELECT [table_name] FROM [helper].[HistTables] WHERE deployment_type = 'START')

WHILE EXISTS(SELECT * FROM #temp_tabs)
BEGIN
	-- the name of the object
	SELECT TOP(1) @object_name = [name] FROM #temp_tabs ORDER BY [name] ASC

	PRINT 'Dropping table ' + @object_name

	SET @stringToExecute = 'DROP TABLE ' + @object_name

	EXEC sp_executesql @stringToExecute

	DELETE #temp_tabs WHERE [name] = @object_name
END

-- functions
SELECT 
	o.[name]
INTO #temp_funcs
FROM sys.sql_modules m 
	INNER JOIN sys.objects o 
		ON m.[object_id] = o.[object_id] 
WHERE o.[type_desc] LIKE '%function%'
	AND o.[name] NOT IN (SELECT [function_name] FROM [helper].[HistFunctions] WHERE deployment_type = 'START')

WHILE EXISTS(SELECT * FROM #temp_funcs)
BEGIN
	-- the name of the object
	SELECT TOP(1) @object_name = [name] FROM #temp_funcs ORDER BY [name] ASC

	PRINT 'Dropping function ' + @object_name

	SET @stringToExecute = 'DROP FUNCTION ' + @object_name

	EXEC sp_executesql @stringToExecute

	DELETE #temp_funcs WHERE [name] = @object_name
END

-- procedures
SELECT
	[name]
INTO #temp_procs
FROM sys.procedures
WHERE [name] NOT IN (SELECT [procedure_name] FROM [helper].[HistProcedures] WHERE deployment_type = 'START')

WHILE EXISTS(SELECT * FROM #temp_procs)
BEGIN
	-- the name of the object
	SELECT TOP(1) @object_name = [name] FROM #temp_procs ORDER BY [name] ASC

	PRINT 'Dropping procedure ' + @object_name

	SET @stringToExecute = 'DROP PROCEDURE ' + @object_name

	EXEC sp_executesql @stringToExecute

	DELETE #temp_procs WHERE [name] = @object_name
END

-- views
SELECT
	[name]
INTO #temp_views
FROM sys.views
WHERE [name] NOT IN (SELECT [view_name] FROM [helper].[HistViews] WHERE deployment_type = 'START')

WHILE EXISTS(SELECT * FROM #temp_views)
BEGIN
	-- the name of the object
	SELECT TOP(1) @object_name = [name] FROM #temp_views ORDER BY [name] ASC

	PRINT 'Dropping view ' + @object_name

	SET @stringToExecute = 'DROP VIEW ' + @object_name

	EXEC sp_executesql @stringToExecute

	DELETE #temp_views WHERE [name] = @object_name
END

-- linked servers
CREATE TABLE #LSTemp2(
	[srv_name] [nvarchar](2000)  NULL,
	[srv_providername] [nvarchar](2000)  NULL,
	[srv_product] [nvarchar](2000)  NULL,
	[srv_datasource] [nvarchar](MAX)  NULL,
	[srv_providerstring] [nvarchar](MAX)  NULL,
	[srv_location] [nvarchar](2000)  NULL,
	[srv_cat] [nvarchar](2000)  NULL
)

INSERT INTO #LSTemp2(
	[srv_name], 
	[srv_providername], 
	[srv_product], 
	[srv_datasource], 
	[srv_providerstring], 
	[srv_location], 
	[srv_cat]
) 
EXEC sys.sp_linkedservers;

SELECT
	[srv_name] AS [name]
INTO #temp_ls
FROM #LSTemp2
WHERE [srv_name] NOT IN (SELECT [server_name] FROM [helper].[HistLinkedServers] WHERE deployment_type = 'START')

WHILE EXISTS(SELECT * FROM #temp_ls)
BEGIN
	-- the name of the object
	SELECT TOP(1) @object_name = [name] FROM #temp_ls ORDER BY [name] ASC

	PRINT 'Dropping linked server ' + @object_name

	SET @stringToExecute = 'EXEC sp_dropserver ''' + @object_name + ''''

	EXEC sp_executesql @stringToExecute

	DELETE #temp_ls WHERE [name] = @object_name
END

-- agent jobs
SELECT [name]
INTO #temp_jobs
FROM msdb.dbo.sysjobs
WHERE [name] NOT IN (SELECT [job_name] FROM [helper].[HistAgentJobs] WHERE deployment_type = 'START')

WHILE EXISTS(SELECT * FROM #temp_jobs)
BEGIN
	-- the name of the object
	SELECT TOP(1) @object_name = [name] FROM #temp_jobs ORDER BY [name] ASC

	PRINT 'Dropping agent job ' + @object_name

	SET @stringToExecute = 'EXEC sp_gelete_job ''' + @object_name + ''''

	EXEC sp_executesql @stringToExecute

	DELETE #temp_jobs WHERE [name] = @object_name
END

--logins
SELECT 
	l.[name]
INTO #temp_logins
FROM sys.syslogins l 
	LEFT JOIN sys.server_principals p 
		ON (l.name = p.name) 
WHERE p.type IN ('S', 'G', 'U') 
	AND l.name <> 'sa'
	AND l.[name] NOT IN (SELECT [login_name] FROM [helper].[HistLogins] WHERE deployment_type = 'START')

WHILE EXISTS(SELECT * FROM #temp_logins)
BEGIN
	-- the name of the object
	SELECT TOP(1) @object_name = [name] FROM #temp_logins ORDER BY [name] ASC

	PRINT 'Dropping login ' + @object_name

	SET @stringToExecute = 'DROP LOGIN ' + @object_name

	EXEC sp_executesql @stringToExecute

	DELETE #temp_logins WHERE [name] = @object_name
END

-- databases
SELECT
	[name]
INTO #temp_dbs
FROM sys.databases
WHERE [name] NOT IN (SELECT 
						database_name 
					FROM [helper].[HistDatabases] 
					WHERE deployment_type = 'START')
	AND database_id NOT IN (1,2,3,4)

WHILE EXISTS(SELECT * FROM #temp_dbs)
BEGIN
	-- the name of the object
	SELECT TOP(1) @object_name = [name] FROM #temp_dbs ORDER BY [name] ASC

	PRINT 'Dropping database ' + @object_name

	SET @stringToExecute = 'DROP DATABASE ' + @object_name

	EXEC sp_executesql @stringToExecute

	DELETE #temp_dbs WHERE [name] = @object_name
END












-- PREVIOUS VERSION OF THE SCRIPT BELOW

--IF(@option = 1)
--BEGIN
--	DECLARE @name NVARCHAR(1000)
--	DECLARE @schema NVARCHAR(1000)
--	DECLARE @database NVARCHAR(1000)
--	DECLARE @definition NVARCHAR(MAX)
--	DECLARE @execString NVARCHAR(MAX)

--	-- ************************************************************************************
--	-- * LOGINS
--	-- ************************************************************************************

--	-- Drop every login whose name is not contained in the helper.Logins table

--	DECLARE cursor_logins CURSOR FOR
--	SELECT [name] FROM sys.syslogins WHERE [name] NOT IN (SELECT [login_name] FROM [helper].[HistLogins]) OPEN cursor_logins

--	FETCH NEXT FROM cursor_logins INTO @name
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Dropping Login ' + @name

--		SET @execString = 'DROP LOGIN ' + @name

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_logins INTO @name
--		END
--	END
--	CLOSE cursor_logins
--	DEALLOCATE cursor_logins

--	-- ************************************************************************************
--	-- * AGENT JOBS
--	-- *
--	-- * - TODO: Recreate the agent jobs that have been altered
--	-- *
--	-- ************************************************************************************

--	-- Drop every agent job whose name is not contained in the helper.AgentJobs table

--	DECLARE cursor_jobs CURSOR FOR
--	SELECT [name] FROM msdb.dbo.sysjobs WHERE [name] NOT IN (SELECT [job_name] FROM [helper].[HistAgentJobs]) OPEN cursor_jobs

--	FETCH NEXT FROM cursor_jobs INTO @name
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Dropping job ' + @name

--		SET @execString = 'EXEC sp_delete_job @job_name=''' + @name + ''';'

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_jobs INTO @name
--		END
--	END
--	CLOSE cursor_jobs
--	DEALLOCATE cursor_jobs

--	-- ************************************************************************************
--	-- * LINKED SERVER
--	-- ************************************************************************************

--	-- Drop every linked server whose name is not contained in the helper.LinkedServers table
	
--	CREATE TABLE #LSTemp(
--		[srv_name] [nvarchar](2000) NOT NULL,
--		[srv_providername] [nvarchar](2000) NULL,
--		[srv_product] [nvarchar](2000) NULL,
--		[srv_datasource] [nvarchar](MAX) NULL,
--		[srv_providerstring] [nvarchar](MAX) NULL,
--		[srv_location] [nvarchar](2000) NULL,
--		[srv_cat] [nvarchar](2000) NULL
--	)

--	INSERT INTO #LSTemp([srv_name], [srv_providername], [srv_product], [srv_datasource], [srv_providerstring], [srv_location], [srv_cat]) EXEC sys.sp_linkedservers;

--	DECLARE cursor_servers CURSOR FOR
--	SELECT [srv_name] FROM #LSTemp WHERE [srv_name] NOT IN (SELECT [server_name] FROM [helper].[HistLinkedServers]) OPEN cursor_servers

--	FETCH NEXT FROM cursor_servers INTO @name
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Dropping linked server ' + @name

--		SET @execString = 'EXEC sp_dropserver @server=''' + @name + ''';'

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_servers INTO @name
--		END
--	END
--	CLOSE cursor_servers
--	DEALLOCATE cursor_servers

--	-- Drop and recreate every linked server that is contained in the helper.LinkedServers table

--	DECLARE @s_name NVARCHAR(1000)
--	DECLARE @s_providername NVARCHAR(1000)
--	DECLARE @s_product NVARCHAR(1000)
--	DECLARE @s_datasource NVARCHAR(1000)
--	DECLARE @s_providerstring NVARCHAR(1000)
--	DECLARE @s_location NVARCHAR(1000)
--	DECLARE @s_cat NVARCHAR(1000)

--	DECLARE cursor_servers CURSOR FOR
--	(SELECT [server_name], [server_providername], [server_product], [server_datasource], [server_providerstring], [server_location], [server_cat] FROM [helper].[HistLinkedServers]) OPEN cursor_servers

--	FETCH NEXT FROM cursor_servers INTO @s_name, @s_providername, @s_product, @s_datasource, @s_providerstring, @s_location, @s_cat
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Recreating linked server ' + @s_name

--		SET @execString = 'EXEC sp_dropserver @server=''' + @s_name + '''
--		GO
		
--		EXEC sp_addlinkedserver @server=''' + @s_name + ''', @srvproduct=''' + @s_product + ''', @provider=' + @s_providername +
--		''', @datasrc=''' + @s_datasource + ''', @location=''' + @s_location + ''', provstr=''' + @s_providerstring + '''
--		GO'

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_servers INTO @s_name, @s_providername, @s_product, @s_datasource, @s_providerstring, @s_location, @s_cat
--		END
--	END
--	CLOSE cursor_servers
--	DEALLOCATE cursor_servers

--	-- ************************************************************************************
--	-- * TABLES
--	-- ************************************************************************************

--	-- Drop every table whose name is not contained in the helper.Tables table

--	DECLARE cursor_tables CURSOR FOR
--	(SELECT [name], SCHEMA_NAME(SCHEMA_ID), DB_NAME(parent_object_id) FROM sys.tables WHERE NOT EXISTS(SELECT * FROM [helper].[HistTables] WHERE [table_name] = [name] AND [schema_name] = SCHEMA_NAME(SCHEMA_ID) 
--	AND [database_name] = DB_NAME(parent_object_id))) OPEN cursor_tables

--	FETCH NEXT FROM cursor_tables INTO @name, @schema, @database
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Dropping Table ' + @schema + '.' + @name

--		SET @execString = 'DROP TABLE ' + @schema + '.' + @name

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_tables INTO @name, @schema, @database
--		END
--	END
--	CLOSE cursor_tables
--	DEALLOCATE cursor_tables

--	-- Drop and recreate every table whose name is contained in the helper.Tables table

--	DECLARE cursor_tables CURSOR FOR
--	(SELECT [base].[table_name], [base].[schema_name], [base].[database_name], [def].[definition] FROM [helper].[HistTables] [base] INNER JOIN [helper].[HistTablesDefinition] [def] ON [base].[table_name] = [def].[table_name]
--	AND [base].[schema_name] = [def].[schema_name] AND [base].[database_name] = [def].[database_name] WHERE [base].[table_name] NOT IN ('HistDatabases', 'HistLogins', 'HistAgentJobs', 'HistLinkedServers', 'HistTables', 
--	'HistTablesDefinition', 'HistViews', 'HistProcedures', 'HistFunctions')) OPEN cursor_tables

--	FETCH NEXT FROM cursor_tables INTO @name, @schema, @database, @definition
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Recreating Table ' + @schema + '.' + @name

--		SET @execString = 'DROP TABLE ' + @schema + '.' + @name

--		EXEC sp_executesql @execString

--		EXEC sp_executesql @definition

--		FETCH NEXT FROM cursor_tables INTO @name, @schema, @database, @definition
--		END
--	END
--	CLOSE cursor_tables
--	DEALLOCATE cursor_tables

--	-- ************************************************************************************
--	-- * VIEWS
--	-- ************************************************************************************

--	-- Drop every view whose name is not contained in the helper.Views table

--	DECLARE cursor_views CURSOR FOR
--	(SELECT [name], SCHEMA_NAME(SCHEMA_ID), DB_NAME(parent_object_id) FROM sys.views WHERE NOT EXISTS(SELECT * FROM [helper].[HistViews] WHERE [name] = [view_name] 
--	AND [schema_name] = SCHEMA_NAME(SCHEMA_ID) AND [database_name] = DB_NAME(parent_object_id))) OPEN cursor_views

--	FETCH NEXT FROM cursor_views INTO @name, @schema, @database
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Dropping View ' + @schema + '.' + @name

--		SET @execString = 'DROP VIEW ' + @schema + '.' + @name

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_views INTO @name, @schema, @database
--		END
--	END
--	CLOSE cursor_views
--	DEALLOCATE cursor_views

--	-- Drop and recreate every view whose name is contained in the helper.Views table

--	DECLARE cursor_views CURSOR FOR
--	(SELECT [view_name], [schema_name], [database_name], [object_definition] FROM [helper].[HistViews]) OPEN cursor_views

--	FETCH NEXT FROM cursor_views INTO @name, @schema, @database, @definition
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Recreating View ' + @schema + '.' + @name

--		SET @execString = 'DROP VIEW ' + @schema + '.' + @name
		
--		EXEC sp_executesql @execString

--		EXEC sp_executesql @definition

--		FETCH NEXT FROM cursor_views INTO @name, @schema, @database, @definition
--		END
--	END
--	CLOSE cursor_views
--	DEALLOCATE cursor_views

--	-- ************************************************************************************
--	-- * PROCEDURES
--	-- ************************************************************************************

--	-- Drop every procedure whose name is not contained in the helper.Procedures table

--	DECLARE cursor_procedures CURSOR FOR
--	(SELECT [name], SCHEMA_NAME(SCHEMA_ID), DB_NAME(parent_object_id) FROM sys.procedures WHERE NOT EXISTS(SELECT * FROM [helper].[HistProcedures] WHERE [name] = [procedure_name] 
--	AND [schema_name] = SCHEMA_NAME(SCHEMA_ID) AND [database_name] = DB_NAME(parent_object_id))) OPEN cursor_procedures

--	FETCH NEXT FROM cursor_procedures INTO @name, @schema, @database
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Dropping Procedure ' + @schema + '.' + @name

--		SET @execString = 'DROP PROCEDURE ' + @schema + '.' + @name

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_procedures INTO @name, @schema, @database
--		END
--	END
--	CLOSE cursor_procedures
--	DEALLOCATE cursor_procedures

--	-- Drop and recreate every procedure whose name is contained in the helper.Procedures table

--	DECLARE cursor_procedures CURSOR FOR
--	(SELECT [procedure_name], [schema_name], [database_name], [object_definition] FROM [helper].[HistProcedures] WHERE [procedure_name] NOT LIKE '%hist_s%') OPEN cursor_procedures

--	FETCH NEXT FROM cursor_procedures INTO @name, @schema, @database, @definition
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Recreating Procedure ' + @schema + '.' + @name

--		SET @execString = 'DROP PROCEDURE ' + @schema + '.' + @name

--		EXEC sp_executesql @execString

--		EXEC sp_executesql @definition

--		FETCH NEXT FROM cursor_procedures INTO @name, @schema, @database, @definition
--		END
--	END
--	CLOSE cursor_procedures
--	DEALLOCATE cursor_procedures

--	-- ************************************************************************************
--	-- * FUNCTIONS
--	-- ************************************************************************************

--	-- Drop every function whose name is not contained in the helper.Functions table

--	DECLARE cursor_functions CURSOR FOR
--	(SELECT [name], SCHEMA_NAME(SCHEMA_ID), DB_NAME(parent_object_id) FROM sys.sql_modules m INNER JOIN sys.objects o ON m.[object_id] = o.[object_id] WHERE o.[type_desc] LIKE '%function%' AND NOT EXISTS(SELECT * FROM [helper].[HistFunctions] WHERE [name] = [function_name] 
--	AND [schema_name] = SCHEMA_NAME(SCHEMA_ID) AND [database_name] = DB_NAME(parent_object_id))) OPEN cursor_functions

--	FETCH NEXT FROM cursor_functions INTO @name, @schema, @database
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Dropping Function ' + @schema + '.' + @name

--		SET @execString = 'DROP FUNCTION ' + @schema + '.' + @name

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_functions INTO @name, @schema, @database
--		END
--	END
--	CLOSE cursor_functions
--	DEALLOCATE cursor_functions

--	-- Drop and recreate every function whose name is contained in the helper.Functions table

--	DECLARE cursor_functions CURSOR FOR
--	(SELECT [function_name], [schema_name], [database_name], [object_definition] FROM [helper].[HistFunctions]) OPEN cursor_functions

--	FETCH NEXT FROM cursor_functions INTO @name, @schema, @database, @definition
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Recreating Function ' + @schema + '.' + @name

--		SET @execString = 'DROP FUNCTION ' + @schema + '.' + @name

--		EXEC sp_executesql @execString

--		EXEC sp_executesql @definition

--		FETCH NEXT FROM cursor_functions INTO @name, @schema, @database, @definition
--		END
--	END
--	CLOSE cursor_functions
--	DEALLOCATE cursor_functions

--	-- ************************************************************************************
--	-- * DATABASES
--	-- *
--	-- * - TODO: Move this to the bottom. Delete the database after the objects on it have
--	-- *		 been deleted.
--	-- *
--	-- ************************************************************************************

--	-- Drop every database whose name is not contained in the helper.Databases table

--	DECLARE cursor_databases CURSOR FOR
--	SELECT [name] FROM sys.databases WHERE [database_id] NOT IN (1,2,3,4) AND [name] NOT IN (SELECT [database_name] FROM [helper].[HistDatabases]) OPEN cursor_databases

--	FETCH NEXT FROM cursor_databases INTO @name
--	WHILE(@@FETCH_STATUS <> -1)
--	BEGIN
--		IF(@@FETCH_STATUS <> -2)
--		BEGIN

--		PRINT 'Dropping database ' + @name

--		SET @execString = 'DROP DATABASE ' + @name

--		EXEC sp_executesql @execString

--		FETCH NEXT FROM cursor_databases INTO @name
--		END
--	END
--	CLOSE cursor_databases
--	DEALLOCATE cursor_databases

--END

----
---- Do everything that has to be done when reverting/stopping here
---- i.e., drop tables, remove triggers


----DROP TABLE IF EXISTS [helper].[HistDatabases];

----DROP TABLE IF EXISTS [helper].[HistLogins];

----DROP TABLE IF EXISTS [helper].[HistAgentJobs];

----DROP TABLE IF EXISTS [helper].[HistLinkedServers];

----DROP TABLE IF EXISTS [helper].[HistTables];

----DROP TABLE IF EXISTS [helper].[HistTablesDefinition]

----DROP TABLE IF EXISTS [helper].[HistViews];

----DROP TABLE IF EXISTS [helper].[HistProcedures];

----DROP TABLE IF EXISTS [helper].[HistFunctions];

END
GO
