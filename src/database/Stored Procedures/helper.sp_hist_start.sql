SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [helper].[sp_hist_start]
AS
DECLARE @stringToExecute nvarchar(max)
DECLARE @name nvarchar(1000)

-- Erstelle das "helper" schema, falls es noch nicht existiert

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'helper')
	BEGIN
		SET @stringToExecute = 'CREATE SCHEMA [helper];'
		EXECUTE(@stringToExecute)
	END;

-- Erstelle die Tabelle in der Informationen bzgl. der Datenbanken gespeichert wird

CREATE TABLE [helper].[Database](
	[timestamp] [datetime],
	[name] [NVARCHAR](2000),
	[database_id] [int],
	[source_database_id] [int],
	[owner_sid] [NVARCHAR](MAX),
	[create_date] [datetime],
	[compatibility_level] [int],
	[collation_name] [NVARCHAR](2000),
	[user_access] [int],
	[user_access_desc] [nvarchar](500),
	[is_read_only] [BIT],
	[is_auto_close_on] [BIT],
	[is_auto_shrink_on] [BIT],
	[state] [int],
	[state_desc] [nvarchar](2000),
	[is_in_standby] [bit],
	[is_cleanly_shutdown] [bit],
	[is_supplemental_logging_enabled] [bit],
	[snapshot_isolation_state] [int],
	[snapshot_isolation_state_desc] [nvarchar](500),
	[is_read_committed_snapshot_on] [bit],
	[recovery_model] [int],
	[recovery_model_desc] [nvarchar](100),
	[page_verify_option] [int],
	[page_verify_option_desc] [nvarchar](100),
	[is_auto_create_stats_on] [bit], --
	[is_auto_create_stats_incremental_on] [bit],
	[is_auto_update_stats_on] [bit],
	[is_auto_update_stats_async_on] [bit],
	[is_ansi_null_default_on] [bit],
	[is_ansi_nulls_on] [bit],
	[is_ansi_padding_on] [bit],
	[is_ansi_warnings_on] [bit],
	[is_arithabort_on] [bit],
	[is_concat_null_yields_null_on] [bit],
	[is_numeric_roundabort_on] [bit],
	[is_quoted_identifier_on] [bit],
	[is_recursive_triggers_on] [bit],
	[is_cursor_close_on_commit_on] [bit],
	[is_local_cursor_default] [bit],
	[is_fulltext_enabled] [bit],
	[is_trustworthy_on] [bit],
	[is_db_chaining_on] [bit],
	[is_parameterization_forced] [bit],
	[is_master_key_encrypted_by_server] [bit],
	[is_query_store_on] [bit],
	[is_published] [bit],
	[is_subscribed] [bit],
	[is_merge_published] [bit],
	[is_distributor] [bit],
	[is_sync_with_backup] [bit],
	[service_broker_guid] [nvarchar](500),
	[is_broker_enabled] [bit],
	[log_reuse_wait] [int],
	[log_reuse_wait_desc] [nvarchar](500),
	[is_date_correlation_on] [bit],
	[is_cdc_enabled] [bit],
	[is_encrypted] [bit],
	[is_honor_broker_priority_on] [bit],
	[replica_id] [uniqueidentifier],
	[group_database_id] [uniqueidentifier],
	[resource_pool_id] [int],
	[default_language_lcid] [int],
	[default_language_name] [nvarchar](2000),
	[default_fulltext_language_lcid] [int],
	[default_fulltext_language_name] [nvarchar](2000),
	[is_nested_triggers_on] [bit],
	[is_transform_noise_words_on] [bit],
	[two_digit_year_cutoff] [nvarchar](MAX),
	[containment] [int],
	[containment_desc] [nvarchar](500),
	[target_recovery_time_in_seconds] [int],
	[delayed_durability] [int],
	[delayed_durability_desc] [nvarchar](500),
	[is_memory_optimized_elevate_to_snapshot_on] [bit],
	[is_federation_member] [bit],
	[is_remote_data_archive_enabled] [bit],
	[is_mixed_page_allocation_on] [bit],
	[is_temporal_history_retention_enabled] [bit],
	[catalog_collation_type] [int],
	[catalog_collation_type_desc] [nvarchar](500),
	[physical_database_name] [nvarchar](2000),
	[is_result_set_caching_on] [bit],
	[is_accelerated_database_recovery_on] [bit],
	[is_tempdb_spill_to_remote_store] [bit],
	[is_stale_page_detection_on] [bit],
	[is_memory_optimized_enabled] [bit]
)

-- Registriere die Datenabanken die bereits existieren in der zuvor erstellen Tabelle 

INSERT INTO [helper].[Database]
SELECT GETDATE(), * FROM sys.databases WHERE database_id NOT IN (1,2,3,4);

-- Erstelle einen update Trigger für jede der registrierten Datenabanken

DECLARE db_cursor CURSOR FOR
SELECT name from [helper].[Database] OPEN db_cursor 

FETCH NEXT FROM db_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating database triggers!'
	CLOSE db_cursor
	DEALLOCATE db_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	INSERT INTO [helper].[Database] SELECT GETDATE(), * FROM sys.databases WHERE name = ' + @name + ';' 

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM db_cursor INTO @name
	END

END
CLOSE db_cursor
DEALLOCATE db_cursor

-- Erstelle die Tabelle in der Informationen bzgl. der Logins gespeichert wird

CREATE TABLE [helper].[Login]
(
	[timestamp] [datetime],
	[sid] [varbinary](MAX),
	[status] [int],
	[createdate] [datetime],
	[updatedate] [datetime],
	[accdate] [datetime],
	[totcpu] [int],
	[totio] [int],
	[spacelimit] [int],
	[timelimit] [int],
	[resultlimit] [int],
	[name] [nvarchar](1000),
	[dbname] [nvarchar](1000),
	[password] [nvarchar](1000),
	[language] [nvarchar] (1000),
	[denylogin] [bit],
	[hasaccess] [bit],
	[instname] [bit],
	[instgroup] [bit],
	[instuser] [bit],
	[sysadmin] [bit],
	[securityadmin] [bit],
	[serveradmin] [bit],
	[setupadmin] [bit],
	[processadmin] [bit],
	[diskadmin] [bit],
	[dbcreator] [bit],
	[bulkadmin] [bit],
	[loginname] [nvarchar](1000)
)

-- Registriere die Logins die bereits existieren in der zuvor erstellen Tabelle

INSERT INTO [helper].[Login]
SELECT GETDATE(), * FROM sys.syslogins;

-- Erstelle einen update Trigger für jede der registrierten Logins

DECLARE login_cursor CURSOR FOR
SELECT name from [helper].[Login] OPEN login_cursor 

FETCH NEXT FROM login_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating login triggers!'
	CLOSE login_cursor
	DEALLOCATE login_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	INSERT INTO [helper].[Login] SELECT GETDATE(), * FROM sys.syslogins WHERE name = ' + @name + ';' 

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM login_cursor INTO @name
	END

END
CLOSE login_cursor
DEALLOCATE login_cursor

-- Erstelle die Tabelle in der Informationen bzgl. der Agent Jobs gespeichert wird

CREATE TABLE [helper].[AgentJob](
	[timestamp] [datetime],
	[job_id] [nvarchar](2000),
	[originating_server_id] [int],
	[name] [nvarchar](2000),
	[enabled] [bit],
	[description] [nvarchar](2000),
	[start_step_id] [int],
	[category_id] [int],
	[owner_sid] [varbinary](MAX),
	[notify_level_eventlog] [int],
	[notify_level_email] [int],
	[notify_level_netsend] [int],
	[notify_level_page] [int],
	[notify_email_operator_id] [int],
	[notify_netsend_operator_id] [int],
	[notify_page_operator_id] [int],
	[delete_level] [int],
	[date_created] [datetime],
	[date_modified] [datetime],
	[version_number] [int]
)

-- Registriere die Agent Jobs die bereits existieren in der zuvor erstellen Tabelle

INSERT INTO [helper].[AgentJob]
SELECT GETDATE(), * FROM msdb.dbo.sysjobs;

-- Erstelle einen update Trigger für jede der registrierten jobs

DECLARE job_cursor CURSOR FOR
SELECT name from [helper].[AgentJob] OPEN job_cursor 

FETCH NEXT FROM job_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating agent job triggers!'
	CLOSE job_cursor
	DEALLOCATE job_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	INSERT INTO [helper].[AgentJob] SELECT GETDATE(), * FROM msdb.dbo.sysjobs WHERE name = ' + @name + ';' 

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM job_cursor INTO @name
	END

END
CLOSE job_cursor
DEALLOCATE job_cursor

-- Erstelle die Tabelle in der Informationen bzgl. der linked server gespeichert wird

CREATE TABLE [helper].[LinkedServer] (
	[timestamp] [datetime],
	[srv_name] [nvarchar](2000),
	[srv_providername] [nvarchar](2000),
	[srv_product] [nvarchar](2000),
	[srv_datasource] [nvarchar](MAX),
	[srv_providerstring] [nvarchar](MAX),
	[srv_location] [nvarchar](2000),
	[srv_cat] [nvarchar](2000)
)


-- Registriere die Linked Server die bereits existieren in der zuvor erstellten tabelle

-- create temp table for sp exec output

CREATE TABLE #ls (
	[srv_name] [nvarchar](2000),
	[srv_providername] [nvarchar](2000),
	[srv_product] [nvarchar](2000),
	[srv_datasource] [nvarchar](MAX),
	[srv_providerstring] [nvarchar](MAX),
	[srv_location] [nvarchar](2000),
	[srv_cat] [nvarchar](2000)
)

-- fill temp table

INSERT INTO #ls
EXEC sys.sp_linkedservers;

INSERT INTO [helper].[LinkedServer]
SELECT GETDATE(), * FROM #ls;

-- Erstelle einen update Trigger für jede der registrierten linked server

DECLARE server_cursor CURSOR FOR
SELECT srv_name from [helper].[LinkedServer] OPEN server_cursor 

FETCH NEXT FROM server_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating linked server triggers!'
	CLOSE server_cursor
	DEALLOCATE server_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	BEGIN
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

	INSERT INTO [helper].[LinkedServer]
	SELECT GETDATE(), * FROM #ls WHERE srv_name = ' + @name + ';
	
	END'

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM server_cursor INTO @name
	END

END
CLOSE server_cursor
DEALLOCATE server_cursor

-- Erstelle die Tabelle in der Informationen bzgl. der Tabellen gespeichert wird

CREATE TABLE [helper].[Table](
	[timestamp] [datetime],
	[name] [nvarchar](100),
	[object_id] [bigint],
	[principal_id] [int],
	[schema_id] [int],
	[parent_object_id] [int],
	[type] [nvarchar](100),
	[type_desc] [nvarchar](100),
	[create_date] [datetime],
	[modify_date] [datetime],
	[is_ms_shipped] [bit],
	[is_published] [bit],
	[is_schema_published] [bit],
	[lob_data_space_id] [int],
	[filestream_data_space_id] [int],
	[max_column_id_used] [int],
	[lock_on_bulk_load] [bit],
	[uses_ansi_nulls] [bit],
	[is_replicated] [bit],
	[has_replication_filter] [bit],
	[is_merge_published] [bit],
	[is_snyc_tran_subscribed] [bit],
	[has_unchecked_assembly_data] [bit],
	[text_in_row_limit] [int],
	[large_value_types_out_of_row] [int],
	[is_tracked_by_cdc] [bit],
	[lock_escalation] [int],
	[lock_escalation_desc] [nvarchar](1000),
	[is_filetable] [bit],
	[is_memory_optimized] [bit],
	[durability] [int],
	[durability_desc] [nvarchar](1000),
	[temporal_type] [int],
	[temporal_type_desc] [nvarchar](2000),
	[history_table_id] [int],
	[is_remote_data_archive_enabled] [bit],
	[is_external] [bit],
	[history_retention_period] [int],
	[history_retention_period_unit] [int],
	[history_retention_period_unit_desc] [nvarchar](1000),
	[is_node] [bit],
	[is_edge] [bit]
)

-- Registriere die Tabellen die bereits existieren in der zuvor erstellen Tabelle

INSERT INTO [helper].[Table]
SELECT GETDATE(), * FROM sys.tables WHERE DB_NAME(parent_object_id) IN (SELECT [name] FROM [helper].[Database]) AND NOT SCHEMA_NAME(SCHEMA_ID) = 'helper';

-- Erstelle einen update trigger für jede der registierten Tabellen

DECLARE tab_cursor CURSOR FOR
SELECT name from [helper].[Table] OPEN tab_cursor 

FETCH NEXT FROM tab_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating table triggers!'
	CLOSE tab_cursor
	DEALLOCATE tab_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	INSERT INTO [helper].[Table] SELECT GETDATE(), * FROM sys.tables WHERE name = ' + @name + ';' 

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM tab_cursor INTO @name
	END

END
CLOSE tab_cursor
DEALLOCATE tab_cursor

-- Erstelle die Tabelle in der Informationen bzgl. der Tabellen-Spalten gespeichert wird

CREATE TABLE [helper].[Column](
	[timestamp] [datetime],
	[object_id] [bigint],
	[name] [nvarchar](1000),
	[column_id] [int],
	[system_type_id] [int],
	[user_type_id] [int],
	[max_length] [int],
	[precision] [int],
	[scale] [int],
	[collation_name] [nvarchar](1000),
	[is_nullable] [bit],
	[is_ansi_padded] [bit],
	[is_rowguidcol] [bit],
	[is_identity] [bit],
	[is_computed] [bit],
	[is_filestream] [bit],
	[is_replicated] [bit],
	[is_non_sql_subscribed] [bit],
	[is_merge_published] [bit],
	[is_dts_replicated] [bit],
	[is_xml_document] [bit],
	[xml_collection_id] [int],
	[default_object_id] [bigint],
	[rule_object_id] [int],
	[is_sparse] [bit],
	[is_column_set] [bit],
	[generated_always_type] [int],
	[generated_always_type_desc] [nvarchar](1000),
	[encryption_type] [int],
	[encryption_type_desc] [nvarchar](1000),
	[encryption_algorithm_name] [nvarchar](1000),
	[column_encryption_key_id] [int],
	[column_encryption_key_database_name] [nvarchar](1000),
	[is_hidden] [bit],
	[is_masked] [bit],
	[graph_type] [int],
	[graph_type_desc] [nvarchar](1000)
)

-- Registriere die Spalten die bereits existieren in der zuvor erstellten Tabelle

INSERT INTO [helper].[Column]
SELECT GETDATE(), * FROM sys.columns WHERE OBJECT_NAME(OBJECT_ID) IN (SELECT [name] FROM [helper].[Table]);

-- Erstelle einen update Trigger für jede der registrierten Spalten

DECLARE col_cursor CURSOR FOR
SELECT name from [helper].[Column] OPEN col_cursor 

FETCH NEXT FROM col_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating column triggers!'
	CLOSE col_cursor
	DEALLOCATE col_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	INSERT INTO [helper].[Column] SELECT GETDATE(), * FROM sys.columns WHERE name = ' + @name + ';' 

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM col_cursor INTO @name
	END

END
CLOSE col_cursor
DEALLOCATE col_cursor

-- Erstelle die Tabelle in der Informationen bzgl. der Views gespeichert wird

CREATE TABLE [helper].[View](
	[timestamp] [datetime],
	[name] [nvarchar](1000),
	[object_id] [int],
	[create_statement] [nvarchar](max)
)

-- Registriere die Views die bereits existieren in der zuvor erstellten Tabelle

INSERT INTO [helper].[View]
SELECT GETDATE(), name, object_id, OBJECT_DEFINITION(OBJECT_ID) FROM sys.views;

-- Erstelle einen update Trigger für jede der registrierten views

DECLARE view_cursor CURSOR FOR
SELECT name from [helper].[View] OPEN view_cursor 

FETCH NEXT FROM view_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating view triggers!'
	CLOSE view_cursor
	DEALLOCATE view_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	SELECT GETDATE(), name, object_id, OBJECT_DEFINITION(OBJECT_ID) FROM sys.views WHERE name = ' + @name + ';' 

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM view_cursor INTO @name
	END

END
CLOSE view_cursor
DEALLOCATE view_cursor

-- Erstelle die Tabelle in der Informationen bzgl. der Procedures gespeichert wird

CREATE TABLE [helper].[Procedure](
	[timestamp] [datetime],
	[name] [nvarchar](1000),
	[object_id] [int],
	[create_statement] [nvarchar](max)
)

-- Registriere die Procedures die bereits existieren in der zuvor erstellten Tabelle

INSERT INTO [helper].[Procedure]
SELECT GETDATE(), name, object_id, OBJECT_DEFINITION(object_id) FROM sys.procedures;

-- Erstelle einen update Trigger für jede der registrierten Procedures

DECLARE proc_cursor CURSOR FOR
SELECT name from [helper].[Procedure] OPEN proc_cursor 

FETCH NEXT FROM proc_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating procedure triggers!'
	CLOSE proc_cursor
	DEALLOCATE proc_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	SELECT GETDATE(), name, object_id, OBJECT_DEFINITION(OBJECT_ID) FROM sys.procedures WHERE name = ' + @name + ';' 

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM proc_cursor INTO @name
	END

END
CLOSE proc_cursor
DEALLOCATE proc_cursor

-- Erstelle die Tabelle in der Informationen bzgl. der Functions gespeichert wird

CREATE TABLE [helper].[Function](
	[timestamp] [datetime],
	[name] [nvarchar](1000),
	[object_id] [int],
	[definition] [nvarchar](max)
)

-- Registriere die Functions die bereits existieren in der zuvor erstellten Tabelle

INSERT INTO [helper].[Function]
SELECT GETDATE(), name, m.OBJECT_ID, definition FROM sys.sql_modules m INNER JOIN sys.objects o ON m.OBJECT_ID = o.OBJECT_ID WHERE type_desc LIKE '%function%';

-- Erstelle einen update Trigger für jede der registrierten Functions

DECLARE fn_cursor CURSOR FOR
SELECT name from [helper].[Function] OPEN fn_cursor 

FETCH NEXT FROM fn_cursor INTO @name
if(@@fetch_status = -1)
BEGIN
	PRINT 'Error occurred while creating function triggers!'
	CLOSE fn_cursor
	DEALLOCATE fn_cursor
END
WHILE(@@fetch_status <> -1) -- while fetching is successful
BEGIN
	if(@@fetch_status <> -2) -- if not fetched row is missing
	BEGIN

	SET @stringToExecute = 'CREATE TRIGGER trigger_helper_' + @name + '
	ON ' + @name + '
	AFTER UPDATE
	AS
	SELECT GETDATE(), name, m.OBJECT_ID, definition FROM sys.sql_modules m INNER JOIN sys.objects o ON m.OBJECT_ID = o.OBJECT_ID WHERE type_desc LIKE ''%function%'' name = ' + @name + ';' 

	EXECUTE(@stringToExecute)
	FETCH NEXT FROM fn_cursor INTO @name
	END

END
CLOSE fn_cursor
DEALLOCATE fn_cursor
GO
