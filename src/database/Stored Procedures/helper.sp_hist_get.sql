SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [helper].[sp_hist_get](@target_time as DATETIME)
AS
BEGIN

DECLARE @stringToExecute nvarchar(max)
DECLARE @definition nvarchar(max)
DECLARE @name nvarchar(1000)
DECLARE @timestamp datetime

-- **********************
-- * Datenbanken        *
-- **********************

-- Entferne Datenbanken die neu sind

DECLARE db_cursor CURSOR FOR
SELECT name from sys.databases where name not in (Select name from [helper].[Database] where timestamp <= @target_time) OPEN db_cursor

FETCH NEXT FROM db_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while removing databases!'
	CLOSE db_cursor
	DEALLOCATE db_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'DROP DATABASE ' + @name + ';'

	PRINT @stringToExecute
	PRINT 'GO;'
	PRINT ''

	FETCH NEXT FROM db_cursor INTO @name
	END

END
CLOSE db_cursor
DEALLOCATE db_cursor

-- Stelle die ursprüngliche version der registrierten Datenbanken wieder her
-- TODO

-- **********************
-- * Logins             *
-- **********************

-- Entferne die Logins die neu sind

DECLARE login_cursor CURSOR FOR
(SELECT name FROM sys.syslogins WHERE name NOT IN (SELECT name FROM [helper].[Login])) OPEN login_cursor

FETCH NEXT FROM login_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while removing logins!'
	PRINT ''
	CLOSE login_cursor
	DEALLOCATE login_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'DROP LOGIN ' + @name + ';' 

	PRINT @stringToExecute
	PRINT 'GO;'
	PRINT ''

	FETCH NEXT FROM login_cursor INTO @name
	END

END
if(CURSOR_STATUS('global', 'login_cursor') = 1)
BEGIN
	CLOSE login_cursor
	DEALLOCATE login_cursor
END

-- Stelle die ursprüngliche version der registrierten logins wieder her

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

DECLARE login_cursor CURSOR FOR
(SELECT DISTINCT l.sid, l.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM [helper].[Login] l LEFT JOIN sys.server_principals p ON (l.name = p.name) WHERE p.type IN ('S', 'G', 'U') AND l.name <> 'sa') OPEN login_cursor

FETCH NEXT FROM login_cursor INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while altering logins!'
	PRINT ''
	CLOSE view_cursor
	DEALLOCATE view_cursor
END
WHILE(@@fetch_status <> -1)
BEGIN
	if(@@fetch_status <> -2)
	BEGIN
		PRINT ''
		PRINT 'DROP LOGIN ' + @name + ';'
		PRINT 'GO;'
		PRINT ''
		if(@type IN ('G', 'U'))
		BEGIN
			SET @tmpstr = 'CREATE LOGIN ''' + @name + ''' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']' 
		END
		ELSE BEGIN
			
			SET @PWD_varbinary = CAST(LOGINPROPERTY(@name, 'PasswordHash') AS varbinary (256));
			EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT;
			EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT;

			SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
			SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name

			SET @tmpstr = 'CREATE LOGIN ''' + @name + ''' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

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
		ELSE if(@hasaccess = 0)
		BEGIN
			SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ''' + @name + ''' '
		END
		if(@is_disabled = 1)
		BEGIN
			SET @tmpstr = @tmpstr + '; ALTER LOGIN ''' + @name + ''' DISABLE'
		END
		PRINT @tmpstr
	END
	FETCH NEXT FROM login_cursor INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
END
if(CURSOR_STATUS('global', 'login_cursor') = 1)
BEGIN
	CLOSE login_cursor
	DEALLOCATE login_cursor
END

-- **********************
-- * Agent Jobs         *
-- **********************

-- Entferne Agent jobs die neu sind

DECLARE job_cursor CURSOR FOR
(SELECT name FROM msdb.dbo.sysjobs WHERE name NOT IN (SELECT name FROM [helper].[AgentJob])) OPEN job_cursor

FETCH NEXT FROM job_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while removing jobs!'
	PRINT ''
	CLOSE job_cursor
	DEALLOCATE job_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'EXEC sp_delete_job @job_name = ' + @name + ';' 

	PRINT @stringToExecute
	PRINT 'GO;'
	PRINT ''

	FETCH NEXT FROM job_cursor INTO @name
	END

END
if(CURSOR_STATUS('global', 'job_cursor') = 1)
BEGIN
	CLOSE job_cursor
	DEALLOCATE job_cursor
END

-- Stelle die ursprüngliche version der registrierten Agent Jobs wieder her
-- TODO

-- **********************
-- * Linked Server      *
-- **********************

-- Entferne Linked server die neu sind

CREATE TABLE #ls (
	[srv_name] [nvarchar](2000),
	[srv_providername] [nvarchar](2000),
	[srv_product] [nvarchar](2000),
	[srv_datasource] [nvarchar](MAX),
	[srv_providerstring] [nvarchar](MAX),
	[srv_location] [nvarchar](2000),
	[srv_cat] [nvarchar](2000)
)

INSERT INTO #ls
EXEC sys.sp_linkedservers;

DECLARE server_cursor CURSOR FOR
(SELECT srv_name FROM #ls WHERE srv_name NOT IN (SELECT srv_name FROM [helper].[LinkedServer])) OPEN server_cursor

FETCH NEXT FROM server_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while removing linked servers!'
	PRINT ''
	CLOSE server_cursor
	DEALLOCATE server_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'EXEC sp_dropserver @server = ' + @name + ';' 

	PRINT @stringToExecute
	PRINT 'GO;'
	PRINT ''

	FETCH NEXT FROM server_cursor INTO @name
	END

END
if(CURSOR_STATUS('global', 'server_cursor') = 1)
BEGIN
	CLOSE server_cursor
	DEALLOCATE server_cursor
END

-- Stelle die ursprüngliche version der registrierten Linked Server wieder her
-- TODO

-- **********************
-- * Tabellen           *
-- **********************
-- TODO

-- **********************
-- * Columns            *
-- **********************
-- TODO

-- **********************
-- * Views              *
-- **********************

-- Entferne Views die neu sind

DECLARE view_cursor CURSOR FOR
(SELECT name FROM sys.views WHERE name NOT IN (SELECT name FROM [helper].[View])) OPEN view_cursor

FETCH NEXT FROM view_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while removing views!'
	PRINT ''
	CLOSE view_cursor			-- todo: If close/deallocta removed here, the if statement below can be removed
	DEALLOCATE view_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'DROP VIEW ' + @name + ';' 

	PRINT @stringToExecute
	PRINT 'GO;'
	PRINT ''

	FETCH NEXT FROM view_cursor INTO @name
	END

END
if(CURSOR_STATUS('global', 'view_cursor') = 1)
BEGIN
	CLOSE view_cursor
	DEALLOCATE view_cursor
END

-- Stelle die ursprüngliche version der registrierten views wieder her

DECLARE view_cursor CURSOR FOR
(SELECT DISTINCT name, MAX(timestamp), create_statement FROM [helper].[View] where timestamp <= @target_time GROUP BY name, create_statement) OPEN view_cursor

FETCH NEXT FROM view_cursor INTO @name, @timestamp, @definition
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while altering views!'
	PRINT ''
	CLOSE view_cursor
	DEALLOCATE view_cursor
END
WHILE(@@fetch_status <> -1)
BEGIN
	if(@@fetch_status <> -2)
	BEGIN
		PRINT 'DROP VIEW ' + @name + ';'
		PRINT 'GO;'
		PRINT ''
		PRINT @definition
		PRINT 'GO;'
		PRINT ''

		FETCH NEXT FROM view_cursor INTO @name, @timestamp, @definition
	END
END
if(CURSOR_STATUS('global', 'view_cursor') = 1)
BEGIN
	CLOSE view_cursor
	DEALLOCATE view_cursor
END

-- **********************
-- * Procedures         *
-- **********************

-- Entferne Procedures die neu sind

DECLARE proc_cursor CURSOR FOR
(SELECT name FROM sys.procedures WHERE name NOT IN (SELECT name FROM [helper].[Procedure])) OPEN proc_cursor

FETCH NEXT FROM proc_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while removing procedures!'
	PRINT ''
	CLOSE proc_cursor
	DEALLOCATE proc_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'DROP PROCEDURE ' + @name + ';' 

	PRINT @stringToExecute
	PRINT 'GO;'
	PRINT ''

	FETCH NEXT FROM proc_cursor INTO @name
	END

END
if(CURSOR_STATUS('global', 'proc_cursor') = 1)
BEGIN
	CLOSE proc_cursor
	DEALLOCATE proc_cursor
END

-- Stelle die ursprüngliche version der registrierten procedures wieder her

DECLARE proc_cursor CURSOR FOR
(SELECT DISTINCT name, MAX(timestamp), create_statement FROM [helper].[Procedure] where timestamp <= @target_time GROUP BY name, create_statement) OPEN proc_cursor

FETCH NEXT FROM proc_cursor INTO @name, @timestamp, @definition
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while altering procedures!'
	PRINT ''
	CLOSE fn_cursor
	DEALLOCATE fn_cursor
END
WHILE(@@fetch_status <> -1)
BEGIN
	if(@@fetch_status <> -2)
	BEGIN
		PRINT 'DROP PROCEDURE ' + @name + ';'
		PRINT 'GO;'
		PRINT ''
		PRINT @definition
		PRINT 'GO;'
		PRINT ''

		FETCH NEXT FROM proc_cursor INTO @name, @timestamp, @definition
	END
END
if(CURSOR_STATUS('global', 'proc_cursor') = 1)
BEGIN
	CLOSE proc_cursor
	DEALLOCATE proc_cursor
END


-- **********************
-- * Functions          *
-- **********************

-- Entferne Functions die neu sind

DECLARE fn_cursor CURSOR FOR
(SELECT name FROM sys.sql_modules m INNER JOIN sys.objects o ON m.OBJECT_ID = o.OBJECT_ID WHERE type_desc LIKE '%function%' AND name NOT IN (SELECT name FROM [helper].[Function])) OPEN fn_cursor

FETCH NEXT FROM fn_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while removing functions!'
	PRINT ''
	CLOSE fn_cursor
	DEALLOCATE fn_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'DROP FUNCTION ' + @name + ';' 

	PRINT @stringToExecute
	PRINT 'GO;'
	PRINT ''

	FETCH NEXT FROM fn_cursor INTO @name
	END

END
if(CURSOR_STATUS('global', 'fn_cursor') = 1)
BEGIN
	CLOSE fn_cursor
	DEALLOCATE fn_cursor
END

-- Stelle die ursprüngliche version der registrierten functions wieder her

DECLARE fn_cursor CURSOR FOR
(SELECT DISTINCT name, MAX(timestamp), definition FROM [helper].[Function] where timestamp <= @target_time GROUP BY name, definition) OPEN fn_cursor

FETCH NEXT FROM fn_cursor INTO @name, @timestamp, @definition
if(@@fetch_status = -1)
BEGIN
	PRINT '-- Error occurred while altering functions!'
	PRINT ''
	CLOSE fn_cursor
	DEALLOCATE fn_cursor
END
WHILE(@@fetch_status <> -1)
BEGIN
	if(@@fetch_status <> -2)
	BEGIN
		PRINT 'DROP FUNCTION ' + @name + ';'
		PRINT 'GO;'
		PRINT ''
		PRINT @definition
		PRINT 'GO;'
		PRINT ''

		FETCH NEXT FROM fn_cursor INTO @name, @timestamp, @definition
	END
END
if(CURSOR_STATUS('global', 'fn_cursor') = 1)
BEGIN
	CLOSE fn_cursor
	DEALLOCATE fn_cursor
END

--
END;
GO
