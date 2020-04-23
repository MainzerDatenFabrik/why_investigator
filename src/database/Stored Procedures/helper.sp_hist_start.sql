SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [helper].[sp_hist_start]
AS
BEGIN

DECLARE @deployment_id UNIQUEIDENTIFIER

SET @deployment_id = NEWID()

DROP TABLE IF EXISTS [helper].[HistDeploymentId]

CREATE TABLE [helper].[HistDeploymentId](
	[timestamp] [DATETIME] NOT NULL,
	[id] INT IDENTITY(1,1) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

INSERT INTO [helper].[HistDeploymentId]([timestamp], [deployment_id]) SELECT GETDATE(), @deployment_id

-- Databases

DROP TABLE IF EXISTS [helper].[HistDatabases];

CREATE TABLE [helper].[HistDatabases](
	[timestamp] [DATETIME] NOT NULL,
	[database_name] [NVARCHAR] (1000) NOT NULL,
	[deployment_type] [NVARCHAR](1000) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

INSERT INTO [helper].[HistDatabases] ([timestamp], [database_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], 'START', @deployment_id FROM sys.databases WHERE [database_id] NOT IN (1, 2, 3, 4);

-- Logins

DROP TABLE IF EXISTS [helper].[HistLogins];

CREATE TABLE [helper].[HistLogins](
	[timestamp] [DATETIME] NOT NULL,
	[login_name] [NVARCHAR](1000) NOT NULL,
	[object_definition] [NVARCHAR](MAX) NULL,
	[deployment_type] [NVARCHAR](1000) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

--INSERT INTO [helper].[HistLogins] ([timestamp], [login_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [loginname], 'START', @deployment_id FROM sys.syslogins;

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

-- Agent Jobs

DROP TABLE IF EXISTS [helper].[HistAgentJobs];

CREATE TABLE [helper].[HistAgentJobs](
	[timestamp] [DATETIME] NOT NULL,
	[job_name] [NVARCHAR](1000) NOT NULL,
	[deployment_type] [NVARCHAR](1000) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

INSERT INTO [helper].[HistAgentJobs] ([timestamp], [job_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], 'START', @deployment_id FROM msdb.dbo.sysjobs;

-- Linked Servers

DROP TABLE IF EXISTS [helper].[HistLinkedServers];

CREATE TABLE [helper].[HistLinkedServers](
	[timestamp] [DATETIME] NOT NULL,
	[server_name] [NVARCHAR](1000) NOT NULL,
	[object_definition] [NVARCHAR](MAX) NULL, --NOT NULL,
	[deployment_type] [NVARCHAR](1000) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

--CREATE TABLE [helper].[HistLinkedServers](
--	[timestamp] [datetime] NOT NULL,
--	[server_name] [NVARCHAR] (1000) NOT NULL,
--	[server_providername] [NVARCHAR](1000) NULL,
--	[server_product] [NVARCHAR](1000) NULL,
--	[server_datasource] [NVARCHAR](MAX) NULL,
--	[server_providerstring] [NVARCHAR](MAX) NULL,
--	[server_location] [NVARCHAR](1000) NULL,
--	[server_cat] [NVARCHAR](1000) NULL,
--	[deployment_type] [NVARCHAR](1000) NOT NULL,
--	[deployment_id] UNIQUEIDENTIFIER NOT NULL
--)

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
	'START', 
	@deployment_id 
FROM #LSTemp;

-- Views

DROP TABLE IF EXISTS [helper].[HistViews];

CREATE TABLE [helper].[HistViews](
	[timestamp] [DATETIME] NOT NULL,
	[view_name] [NVARCHAR](1000) NOT NULL,
	[schema_name] [NVARCHAR](1000) NOT NULL,
	[object_definition] [NVARCHAR](MAX) NOT NULL,
	[database_name] [NVARCHAR](1000) NOT NUll,
	[deployment_type] [NVARCHAR](1000) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

INSERT INTO [helper].[HistViews]([timestamp], [view_name], [schema_name], [object_definition], [database_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], SCHEMA_NAME(SCHEMA_ID), OBJECT_DEFINITION(object_id), DB_NAME(parent_object_id), 'START', @deployment_id FROM sys.views;

-- Procedures

DROP TABLE IF EXISTS [helper].[HistProcedures];

CREATE TABLE [helper].[HistProcedures](
	[timestamp] [DATETIME] NOT NULL,
	[procedure_name] [NVARCHAR](1000) NOT NULL,
	[schema_name] [NVARCHAR](1000) NOT NULL,
	[object_definition] [NVARCHAR](MAX) NOT NULL,
	[database_name] [NVARCHAR](1000) NOT NUll,
	[deployment_type] [NVARCHAR](1000) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

INSERT INTO [helper].[HistProcedures]([timestamp], [procedure_name], [schema_name], [object_definition], [database_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], SCHEMA_NAME(SCHEMA_ID), OBJECT_DEFINITION(object_id), DB_NAME(parent_object_id), 'START', @deployment_id FROM sys.procedures;

-- Functions

DROP TABLE IF EXISTS [helper].[HistFunctions];

CREATE TABLE [helper].[HistFunctions](
	[timestamp] [DATETIME] NOT NULL,
	[function_name] [NVARCHAR](1000) NOT NULL,
	[schema_name] [NVARCHAR](1000) NOT NULL,
	[object_definition] [NVARCHAR](MAX) NOT NULL,
	[database_name] [NVARCHAR](1000) NOT NUll,
	[deployment_type] [NVARCHAR](1000) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

INSERT INTO [helper].[HistFunctions]([timestamp], [function_name], [schema_name], [object_definition], [database_name], [deployment_type], [deployment_id]) SELECT GETDATE(), [name], SCHEMA_NAME(SCHEMA_ID), [definition], DB_NAME(o.parent_object_id), 'START', @deployment_id FROM sys.sql_modules m INNER JOIN sys.objects o ON m.[object_id] = o.[object_id] WHERE o.[type_desc] LIKE '%function%';

---- Tables

--DROP TABLE IF EXISTS [helper].[HistTables];

--CREATE TABLE [helper].[HistTables](
--	[timestamp] [DATETIME] NOT NULL,
--	[table_name] [NVARCHAR](1000) NOT NULL,
--	[schema_name] [NVARCHAR](1000) NOT NULL,
--	[database_name] [NVARCHAR](1000) NULL,
--	[definition] [NVARCHAR](MAX) NULL,
--	[deployment_type] [NVARCHAR](1000) NOT NULL,
--	[deployment_id] UNIQUEIDENTIFIER NOT NULL
--)

--INSERT INTO [helper].[HistTables]([timestamp], [table_name], [schema_name], [database_name], [deployment_type], [deployment_id])
--SELECT GETDATE(), [name], SCHEMA_NAME(SCHEMA_ID), DB_NAME(parent_object_id), 'START', @deployment_id
--FROM sys.tables

-- Tables Definition

DROP TABLE IF EXISTS [helper].[HistTables]

CREATE TABLE [helper].[HistTables](
	[timestamp] [DATETIME] NOT NULL,
	[schema_name] [NVARCHAR](1000) NOT NULL,
	[table_name] [NVARCHAR](1000) NOT NULL,
	[database_name] [NVARCHAR](1000) NOT NULL,
	[definition] [NVARCHAR](MAX) NULL,
	[deployment_type] [NVARCHAR](1000) NOT NULL,
	[deployment_id] UNIQUEIDENTIFIER NOT NULL
)

CREATE TABLE #Temp(
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

	INSERT INTO #Temp([schema_name], [table_name], [definition], [database_name]) EXEC dbo.sp_GetDDL @object_name

	FETCH NEXT FROM table_cursor INTO @table, @schema
	END
END
CLOSE table_cursor
DEALLOCATE table_cursor

INSERT INTO [helper].[HistTables]([timestamp], [schema_name], [table_name], [database_name], [definition], [deployment_type], [deployment_id])
SELECT GETDATE(), schema_name, table_name, database_name, definition, 'START', @deployment_id FROM #Temp

END
GO
