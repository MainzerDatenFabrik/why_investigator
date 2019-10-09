package com.mainzerdatenfabrik.main.utils;

import com.mainzerdatenfabrik.main.logging.Logger;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;

public class UtilsJDBC {

    // The name of the protocol table (i.e., the log history table)
    public static String PROTOCOL_TABLE_NAME = "FileProtocols";

    // The name of the table all the zip files are getting registered in
    public static String PROJECT_LOG_TABLE_NAME = "ProjectLog";

    public static final String SCHEMA_STAGE = "stage";

    // Indicates that no specific database is used
    public static final String NO_SPECIFIC_DATABASE = "";

    // One of the two procedures required to transfer users from one server to another
    private static final String USER_TRANSFER_PROC_1 =
            "CREATE PROCEDURE [dbo].[sp_hexadecimal]\n" +
                    "   @binvalue varbinary(256),\n" +
                    "   @hexvalue varchar (514) OUTPUT\n" +
                    "AS\n" +
                    "DECLARE @charvalue varchar (514)\n" +
                    "DECLARE @i int\n" +
                    "DECLARE @length int\n" +
                    "DECLARE @hexstring char(16)\n" +
                    "SELECT @charvalue = '0x'\n" +
                    "SELECT @i = 1\n" +
                    "SELECT @length = DATALENGTH (@binvalue)\n" +
                    "SELECT @hexstring = '0123456789ABCDEF'\n" +
                    "WHILE (@i <= @length)\n" +
                    "BEGIN\n" +
                    "   DECLARE @tempint int\n" +
                    "   DECLARE @firstint int\n" +
                    "   DECLARE @secondint int\n" +
                    "   SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))\n" +
                    "   SELECT @firstint = FLOOR(@tempint/16)\n" +
                    "   SELECT @secondint = @tempint - (@firstint*16)\n" +
                    "   SELECT @charvalue = @charvalue +\n" +
                    "   SUBSTRING(@hexstring, @firstint+1, 1) +\n" +
                    "   SUBSTRING(@hexstring, @secondint+1, 1)\n" +
                    "   SELECT @i = @i + 1\n" +
                    "END\n" +
                    "SELECT @hexvalue = @charvalue\n" +
                    "RETURN 1";

    // One of the two procedures required to transfer users from one server to another
    private static final String USER_TRANSFER_PROC_2 =
            "CREATE PROCEDURE [dbo].[sp_help_revlogin] @login_name sysname = NULL AS\n" +
                    "DECLARE @name sysname\n" +
                    "DECLARE @type varchar (1)\n" +
                    "DECLARE @hasaccess int\n" +
                    "DECLARE @denylogin int\n" +
                    "DECLARE @is_disabled int\n" +
                    "DECLARE @PWD_varbinary  varbinary (256)\n" +
                    "DECLARE @PWD_string  varchar (514)\n" +
                    "DECLARE @SID_varbinary varbinary (85)\n" +
                    "DECLARE @SID_string varchar (514)\n" +
                    "DECLARE @tmpstr  varchar (1024)\n" +
                    "DECLARE @is_policy_checked varchar (3)\n" +
                    "DECLARE @is_expiration_checked varchar (3)\n" +
                    "DECLARE @defaultdb sysname\n" +
                    "IF (@login_name IS NULL)\n" +
                    "  DECLARE login_curs CURSOR FOR\n" +
                    "      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM \n" +
                    "sys.server_principals p LEFT JOIN sys.syslogins l\n" +
                    "      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'\n" +
                    "ELSE\n" +
                    "  DECLARE login_curs CURSOR FOR\n" +
                    "      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM \n" +
                    "sys.server_principals p LEFT JOIN sys.syslogins l\n" +
                    "      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name\n" +
                    "OPEN login_curs\n" +
                    "FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin\n" +
                    "IF (@@fetch_status = -1)\n" +
                    "BEGIN\n" +
                    "  PRINT 'No login(s) found.'\n" +
                    "  CLOSE login_curs\n" +
                    "  DEALLOCATE login_curs\n" +
                    "  RETURN -1\n" +
                    "END\n" +
                    "SET @tmpstr = '/* sp_help_revlogin script '\n" +
                    "PRINT @tmpstr\n" +
                    "SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'\n" +
                    "PRINT @tmpstr\n" +
                    "PRINT ''\n" +
                    "WHILE (@@fetch_status <> -1)\n" +
                    "BEGIN\n" +
                    "  IF (@@fetch_status <> -2)\n" +
                    "  BEGIN\n" +
                    "    PRINT ''\n" +
                    "    SET @tmpstr = '-- Login: ' + @name\n" +
                    "    PRINT @tmpstr\n" +
                    "    IF (@type IN ( 'G', 'U'))\n" +
                    "    BEGIN -- NT authenticated account/group\n" +
                    "      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'\n" +
                    "    END\n" +
                    "    ELSE BEGIN -- SQL Server authentication\n" +
                    "        -- obtain password and sid\n" +
                    "            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )\n" +
                    "        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT\n" +
                    "        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT\n" +
                    "        -- obtain password policy state\n" +
                    "        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name\n" +
                    "        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name\n" +
                    "            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'\n" +
                    "        IF ( @is_policy_checked IS NOT NULL )\n" +
                    "        BEGIN\n" +
                    "          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked\n" +
                    "        END\n" +
                    "        IF ( @is_expiration_checked IS NOT NULL )\n" +
                    "        BEGIN\n" +
                    "          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked\n" +
                    "        END\n" +
                    "    END\n" +
                    "    IF (@denylogin = 1)\n" +
                    "    BEGIN -- login is denied access\n" +
                    "      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )\n" +
                    "    END\n" +
                    "    ELSE IF (@hasaccess = 0)\n" +
                    "    BEGIN -- login exists but does not have access\n" +
                    "      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )\n" +
                    "    END\n" +
                    "    IF (@is_disabled = 1)\n" +
                    "    BEGIN -- login is disabled\n" +
                    "      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'\n" +
                    "    END\n" +
                    "    PRINT @tmpstr\n" +
                    "  END\n" +
                    "\n" +
                    "  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin\n" +
                    "   END\n" +
                    "CLOSE login_curs\n" +
                    "DEALLOCATE login_curs\n" +
                    "RETURN 1";

    // A query that returns create statements for user defined types
    private static final String USER_DEFINED_TYPES_QUERY = "SELECT '\n" +
            "IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N''' + st.[name] + ''' AND ss.name = N''' + ss.[name] + ''')\n" +
            "   DROP TYPE ' + QUOTENAME(ss.name, '[') + '.' + QUOTENAME(st.name, '[') + ';\n" +
            "CREATE TYPE ' + QUOTENAME(ss.name, '[') + '.' + QUOTENAME(st.name, '[') + ' FROM ' +\n" +
            "QUOTENAME(bs.[name], '[') +\n" +
            "   CASE bs.[name]\n" +
            "       WHEN 'char' THEN (CASE ISNULL(st.max_length, 0) WHEN 0 THEN '' WHEN -1 THEN '(MAX)' ELSE '(' + convert(varchar(10), st.max_length) + ')' END)\n" +
            "       WHEN 'nchar' THEN (CASE ISNULL(st.max_length, 0) WHEN 0 THEN '' WHEN -1 THEN '(MAX)' ELSE '(' + convert(varchar(10), st.max_length/2) + ')' END)\n" +
            "       WHEN 'varchar' THEN (CASE ISNULL(st.max_length, 0) WHEN 0 THEN '' WHEN -1 THEN '(MAX)' ELSE '(' + convert(varchar(10), st.max_length) + ')' END)\n" +
            "       WHEN 'nvarchar' THEN (CASE ISNULL(st.max_length, 0) WHEN 0 THEN '' WHEN -1 THEN '(MAX)' ELSE '(' + convert(varchar(10), st.max_length/2) + ')' END)\n" +
            "       WHEN 'numeric' THEN (CASE ISNULL(st.[precision], 0) WHEN 0 THEN '' ELSE '(' + convert(varchar(10), st.[precision]) + ', ' + convert(varchar(10), st.[scale]) + ')' END)\n" +
            "       WHEN 'decimal' THEN (CASE ISNULL(st.[precision], 0) WHEN 0 THEN '' ELSE '(' + convert(varchar(10), st.[precision]) + ', ' + convert(varchar(10), st.[scale]) + ')' END)\n" +
            "       WHEN 'varbinary' THEN (CASE st.max_length WHEN -1 THEN '(max)' ELSE '(' + convert(varchar(10), st.max_length) + ')' END)\n" +
            "       ELSE ''\n" +
            "   END + ';'\n" +
            "FROM sys.types st\n" +
            "   INNER JOIN sys.schemas ss ON st.[schema_id] = ss.[schema_id]\n" +
            "   INNER JOIN sys.types bs ON bs.[user_type_id] = st.[system_type_id]\n" +
            "WHERE st.[is_user_defined] = 1 -- exclude system types\n" +
            "ORDER BY st.[name], ss.[name]";

    // A query that returns create statements for the fulltext catalog
    private static final String FULLTEXT_CATALOG_QUERY =
            "DECLARE @IndexesCount INT, @RequiredCatalogs INT, @CatalogName VARCHAR(128)SET @IndexesCount = (SELECT COUNT(1) FROM [sys].[fulltext_indexes])\n" +
                    "SET @RequiredCatalogs = (@IndexesCount/7)+1\n" +
                    "SET @CatalogName = (SELECT [name] FROM [sys].[fulltext_catalogs])\n" +
                    "-- Data\n" +
                    "CREATE TABLE #Info ([Id] INT IDENTITY(0, 1), [Table] VARCHAR(128), [Schema] VARCHAR(128), [Index] VARCHAR(128), [Columns] VARCHAR(MAX))\n" +
                    "INSERT INTO #Info ([Table], [Schema], [Index], [Columns])\n" +
                    "SELECT [t].[name] [Table], SCHEMA_NAME([t].[schema_id]) [Schema],[i].[name] [Index],\n" +
                    "      STUFF((SELECT (', [' + [c].[name] + ']')\n" +
                    "              FROM [sys].[fulltext_index_columns] [ic]\n" +
                    "              INNER JOIN [sys].[columns] [c] ON [c].[object_id] = [ic].[object_id] AND [c].[column_id] = [ic].[column_id]\n" +
                    "              WHERE [ic].[object_id] = [fi].[object_id]\n" +
                    "              FOR XML PATH('')), 1, 2, '') [Columns]\n" +
                    "FROM [sys].[fulltext_indexes] [fi]\n" +
                    "INNER JOIN [sys].[tables] [t] ON [t].[object_id] = [fi].[object_id]\n" +
                    "INNER JOIN [sys].[indexes] [i] ON [i].[object_id] = [fi].[object_id] AND [i].[index_id] = [fi].[unique_index_id]\n" +
                    "ORDER BY [t].[name]\n" +
                    ";WITH [mycte] AS (\n" +
                    "  SELECT 1 [DataValue]\n" +
                    "  UNION ALL\n" +
                    "  SELECT [DataValue] + 1\n" +
                    "    FROM [mycte]\n" +
                    "   WHERE [DataValue] + 1 <= @RequiredCatalogs)\n" +
                    "SELECT 'CREATE FULLTEXT CATALOG [' + @CatalogName + CAST([DataValue] AS VARCHAR)\n" +
                    "      + '] WITH ACCENT_SENSITIVITY = ON AUTHORIZATION [dbo];' [-- Create new catalogs]\n" +
                    " FROM [mycte]\n" +
                    "-- OPTION (MAXRECURSION 0)\n" +
                    "-- Create fulltext indexes\n" +
                    "UNION\n" +
                    "SELECT 'CREATE FULLTEXT INDEX ON [' + [Schema] + '].[' + [Table] + '] (' + [Columns]\n" +
                    "     + ') KEY INDEX [' + [Index] + '] ON [' + @CatalogName\n" +
                    "     + CAST(([Id]%@RequiredCatalogs) + 1 AS VARCHAR) + '];' [-- Create fulltext indexes]\n" +
                    " FROM #Info [i]\n" +
                    "DROP TABLE #Info";

    // A query that returns create statements for the table indexes
    private static final String TABLE_INDEXES_QUERY =
            "declare @SchemaName varchar(100)declare @TableName varchar(256)\n" +
                    "declare @IndexName varchar(256)\n" +
                    "declare @ColumnName varchar(100)\n" +
                    "declare @is_unique varchar(100)\n" +
                    "declare @IndexTypeDesc varchar(100)\n" +
                    "declare @FileGroupName varchar(100)\n" +
                    "declare @is_disabled varchar(100)\n" +
                    "declare @IndexOptions varchar(max)\n" +
                    "declare @IndexColumnId int\n" +
                    "declare @IsDescendingKey int \n" +
                    "declare @IsIncludedColumn int\n" +
                    "declare @TSQLScripCreationIndex varchar(max)\n" +
                    "declare @TSQLScripDisableIndex varchar(max)\n" +
                    "\n" +
                    "declare CursorIndex cursor for\n" +
                    " select schema_name(t.schema_id) [schema_name], t.name, ix.name,\n" +
                    " case when ix.is_unique = 1 then 'UNIQUE ' else '' END \n" +
                    " , ix.type_desc,\n" +
                    " case when ix.is_padded=1 then 'PAD_INDEX = ON, ' else 'PAD_INDEX = OFF, ' end\n" +
                    " + case when ix.allow_page_locks=1 then 'ALLOW_PAGE_LOCKS = ON, ' else 'ALLOW_PAGE_LOCKS = OFF, ' end\n" +
                    " + case when ix.allow_row_locks=1 then  'ALLOW_ROW_LOCKS = ON, ' else 'ALLOW_ROW_LOCKS = OFF, ' end\n" +
                    " + case when INDEXPROPERTY(t.object_id, ix.name, 'IsStatistics') = 1 then 'STATISTICS_NORECOMPUTE = ON, ' else 'STATISTICS_NORECOMPUTE = OFF, ' end\n" +
                    " + case when ix.ignore_dup_key=1 then 'IGNORE_DUP_KEY = ON, ' else 'IGNORE_DUP_KEY = OFF, ' end\n" +
                    " + 'SORT_IN_TEMPDB = OFF, FILLFACTOR =' + CAST(ix.fill_factor AS VARCHAR(3)) AS IndexOptions\n" +
                    " , ix.is_disabled , FILEGROUP_NAME(ix.data_space_id) FileGroupName\n" +
                    " from sys.tables t \n" +
                    " inner join sys.indexes ix on t.object_id=ix.object_id\n" +
                    " where ix.type>0 and ix.is_primary_key=0 and ix.is_unique_constraint=0 --and schema_name(tb.schema_id)= @SchemaName and tb.name=@TableName\n" +
                    " and t.is_ms_shipped=0 and t.name<>'sysdiagrams'\n" +
                    " order by schema_name(t.schema_id), t.name, ix.name\n" +
                    "\n" +
                    "open CursorIndex\n" +
                    "fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique, @IndexTypeDesc, @IndexOptions,@is_disabled, @FileGroupName\n" +
                    "\n" +
                    "while (@@fetch_status=0)\n" +
                    "begin\n" +
                    " declare @IndexColumns varchar(max)\n" +
                    " declare @IncludedColumns varchar(max)\n" +
                    " \n" +
                    " set @IndexColumns=''\n" +
                    " set @IncludedColumns=''\n" +
                    " \n" +
                    " declare CursorIndexColumn cursor for \n" +
                    "  select col.name, ixc.is_descending_key, ixc.is_included_column\n" +
                    "  from sys.tables tb \n" +
                    "  inner join sys.indexes ix on tb.object_id=ix.object_id\n" +
                    "  inner join sys.index_columns ixc on ix.object_id=ixc.object_id and ix.index_id= ixc.index_id\n" +
                    "  inner join sys.columns col on ixc.object_id =col.object_id  and ixc.column_id=col.column_id\n" +
                    "  where ix.type>0 and (ix.is_primary_key=0 or ix.is_unique_constraint=0)\n" +
                    "  and schema_name(tb.schema_id)=@SchemaName and tb.name=@TableName and ix.name=@IndexName\n" +
                    "  order by ixc.index_column_id\n" +
                    " \n" +
                    " open CursorIndexColumn \n" +
                    " fetch next from CursorIndexColumn into  @ColumnName, @IsDescendingKey, @IsIncludedColumn\n" +
                    " \n" +
                    " while (@@fetch_status=0)\n" +
                    " begin\n" +
                    "  if @IsIncludedColumn=0 \n" +
                    "   set @IndexColumns=@IndexColumns + @ColumnName  + case when @IsDescendingKey=1  then ' DESC, ' else  ' ASC, ' end\n" +
                    "  else \n" +
                    "   set @IncludedColumns=@IncludedColumns  + @ColumnName  +', ' \n" +
                    "\n" +
                    "  fetch next from CursorIndexColumn into @ColumnName, @IsDescendingKey, @IsIncludedColumn\n" +
                    " end\n" +
                    "\n" +
                    " close CursorIndexColumn\n" +
                    " deallocate CursorIndexColumn\n" +
                    "\n" +
                    " set @IndexColumns = substring(@IndexColumns, 1, len(@IndexColumns)-1)\n" +
                    " set @IncludedColumns = case when len(@IncludedColumns) >0 then substring(@IncludedColumns, 1, len(@IncludedColumns)-1) else '' end\n" +
                    " --  print @IndexColumns\n" +
                    " --  print @IncludedColumns\n" +
                    "\n" +
                    " set @TSQLScripCreationIndex =''\n" +
                    " set @TSQLScripDisableIndex =''\n" +
                    " set @TSQLScripCreationIndex='CREATE '+ @is_unique  +@IndexTypeDesc + ' INDEX ' +QUOTENAME(@IndexName)+' ON ' + QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName)+ '('+@IndexColumns+') '+ \n" +
                    "  case when len(@IncludedColumns)>0 then CHAR(13) +'INCLUDE (' + @IncludedColumns+ ')' else '' end + CHAR(13)+'WITH (' + @IndexOptions+ ') ON ' + QUOTENAME(@FileGroupName) + ';'  \n" +
                    "\n" +
                    " if @is_disabled=1 \n" +
                    "  set  @TSQLScripDisableIndex=  CHAR(13) +'ALTER INDEX ' +QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName) + ' DISABLE;' + CHAR(13) \n" +
                    "\n" +
                    " print @TSQLScripCreationIndex\n" +
                    " print @TSQLScripDisableIndex\n" +
                    "\n" +
                    " fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique, @IndexTypeDesc, @IndexOptions,@is_disabled, @FileGroupName\n" +
                    "\n" +
                    "end\n" +
                    "close CursorIndex\n" +
                    "deallocate CursorIndex\n" +
                    "\n" +
                    "\n" +
                    "\n" +
                    "\n" +
                    "SELECT \n" +
                    "    DB_NAME() AS database_name,\n" +
                    "    sc.name + N'.' + t.name AS table_name,\n" +
                    "    (SELECT MAX(user_reads) \n" +
                    "        FROM (VALUES (last_user_seek), (last_user_scan), (last_user_lookup)) AS value(user_reads)) AS last_user_read,\n" +
                    "    last_user_update,\n" +
                    "    CASE si.index_id WHEN 0 THEN N'/* No create statement (Heap) */'\n" +
                    "    ELSE \n" +
                    "        CASE is_primary_key WHEN 1 THEN\n" +
                    "            N'ALTER TABLE ' + QUOTENAME(sc.name) + N'.' + QUOTENAME(t.name) + N' ADD CONSTRAINT ' + QUOTENAME(si.name) + N' PRIMARY KEY ' +\n" +
                    "                CASE WHEN si.index_id > 1 THEN N'NON' ELSE N'' END + N'CLUSTERED '\n" +
                    "            ELSE N'CREATE ' + \n" +
                    "                CASE WHEN si.is_unique = 1 then N'UNIQUE ' ELSE N'' END +\n" +
                    "                CASE WHEN si.index_id > 1 THEN N'NON' ELSE N'' END + N'CLUSTERED ' +\n" +
                    "                N'INDEX ' + QUOTENAME(si.name) + N' ON ' + QUOTENAME(sc.name) + N'.' + QUOTENAME(t.name) + N' '\n" +
                    "        END +\n" +
                    "        /* key def */ N'(' + key_definition + N')' +\n" +
                    "        /* includes */ CASE WHEN include_definition IS NOT NULL THEN \n" +
                    "            N' INCLUDE (' + include_definition + N')'\n" +
                    "            ELSE N''\n" +
                    "        END +\n" +
                    "        /* filters */ CASE WHEN filter_definition IS NOT NULL THEN \n" +
                    "            N' WHERE ' + filter_definition ELSE N''\n" +
                    "        END +\n" +
                    "        /* with clause - compression goes here */\n" +
                    "        CASE WHEN row_compression_partition_list IS NOT NULL OR page_compression_partition_list IS NOT NULL \n" +
                    "            THEN N' WITH (' +\n" +
                    "                CASE WHEN row_compression_partition_list IS NOT NULL THEN\n" +
                    "                    N'DATA_COMPRESSION = ROW ' + CASE WHEN psc.name IS NULL THEN N'' ELSE + N' ON PARTITIONS (' + row_compression_partition_list + N')' END\n" +
                    "                ELSE N'' END +\n" +
                    "                CASE WHEN row_compression_partition_list IS NOT NULL AND page_compression_partition_list IS NOT NULL THEN N', ' ELSE N'' END +\n" +
                    "                CASE WHEN page_compression_partition_list IS NOT NULL THEN\n" +
                    "                    N'DATA_COMPRESSION = PAGE ' + CASE WHEN psc.name IS NULL THEN N'' ELSE + N' ON PARTITIONS (' + page_compression_partition_list + N')' END\n" +
                    "                ELSE N'' END\n" +
                    "            + N')'\n" +
                    "            ELSE N''\n" +
                    "        END +\n" +
                    "        /* ON where? filegroup? partition scheme? */\n" +
                    "        ' ON ' + CASE WHEN psc.name is null \n" +
                    "            THEN ISNULL(QUOTENAME(fg.name),N'')\n" +
                    "            ELSE psc.name + N' (' + partitioning_column.column_name + N')' \n" +
                    "            END\n" +
                    "        + N';'\n" +
                    "    END AS index_create_statement,\n" +
                    "    si.index_id,\n" +
                    "    si.name AS index_name,\n" +
                    "    partition_sums.reserved_in_row_GB,\n" +
                    "    partition_sums.reserved_LOB_GB,\n" +
                    "    partition_sums.row_count,\n" +
                    "    stat.user_seeks,\n" +
                    "    stat.user_scans,\n" +
                    "    stat.user_lookups,\n" +
                    "    user_updates AS queries_that_modified,\n" +
                    "    partition_sums.partition_count,\n" +
                    "    si.allow_page_locks,\n" +
                    "    si.allow_row_locks,\n" +
                    "    si.is_hypothetical,\n" +
                    "    si.has_filter,\n" +
                    "    si.fill_factor,\n" +
                    "    si.is_unique,\n" +
                    "    ISNULL(pf.name, '/* Not partitioned */') AS partition_function,\n" +
                    "    ISNULL(psc.name, fg.name) AS partition_scheme_or_filegroup,\n" +
                    "    t.create_date AS table_created_date,\n" +
                    "    t.modify_date AS table_modify_date\n" +
                    "FROM sys.indexes AS si\n" +
                    "JOIN sys.tables AS t ON si.object_id=t.object_id\n" +
                    "JOIN sys.schemas AS sc ON t.schema_id=sc.schema_id\n" +
                    "LEFT JOIN sys.dm_db_index_usage_stats AS stat ON \n" +
                    "    stat.database_id = DB_ID() \n" +
                    "    and si.object_id=stat.object_id \n" +
                    "    and si.index_id=stat.index_id\n" +
                    "LEFT JOIN sys.partition_schemes AS psc ON si.data_space_id=psc.data_space_id\n" +
                    "LEFT JOIN sys.partition_functions AS pf ON psc.function_id=pf.function_id\n" +
                    "LEFT JOIN sys.filegroups AS fg ON si.data_space_id=fg.data_space_id\n" +
                    "/* Key list */ OUTER APPLY ( SELECT STUFF (\n" +
                    "    (SELECT N', ' + QUOTENAME(c.name) +\n" +
                    "        CASE ic.is_descending_key WHEN 1 then N' DESC' ELSE N'' END\n" +
                    "    FROM sys.index_columns AS ic \n" +
                    "    JOIN sys.columns AS c ON \n" +
                    "        ic.column_id=c.column_id  \n" +
                    "        and ic.object_id=c.object_id\n" +
                    "    WHERE ic.object_id = si.object_id\n" +
                    "        and ic.index_id=si.index_id\n" +
                    "        and ic.key_ordinal > 0\n" +
                    "    ORDER BY ic.key_ordinal FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS keys ( key_definition )\n" +
                    "/* Partitioning Ordinal */ OUTER APPLY (\n" +
                    "    SELECT MAX(QUOTENAME(c.name)) AS column_name\n" +
                    "    FROM sys.index_columns AS ic \n" +
                    "    JOIN sys.columns AS c ON \n" +
                    "        ic.column_id=c.column_id  \n" +
                    "        and ic.object_id=c.object_id\n" +
                    "    WHERE ic.object_id = si.object_id\n" +
                    "        and ic.index_id=si.index_id\n" +
                    "        and ic.partition_ordinal = 1) AS partitioning_column\n" +
                    "/* Include list */ OUTER APPLY ( SELECT STUFF (\n" +
                    "    (SELECT N', ' + QUOTENAME(c.name)\n" +
                    "    FROM sys.index_columns AS ic \n" +
                    "    JOIN sys.columns AS c ON \n" +
                    "        ic.column_id=c.column_id  \n" +
                    "        and ic.object_id=c.object_id\n" +
                    "    WHERE ic.object_id = si.object_id\n" +
                    "        and ic.index_id=si.index_id\n" +
                    "        and ic.is_included_column = 1\n" +
                    "    ORDER BY c.name FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS includes ( include_definition )\n" +
                    "/* Partitions */ OUTER APPLY ( \n" +
                    "    SELECT \n" +
                    "        COUNT(*) AS partition_count,\n" +
                    "        CAST(SUM(ps.in_row_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_in_row_GB,\n" +
                    "        CAST(SUM(ps.lob_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_LOB_GB,\n" +
                    "        SUM(ps.row_count) AS row_count\n" +
                    "    FROM sys.partitions AS p\n" +
                    "    JOIN sys.dm_db_partition_stats AS ps ON\n" +
                    "        p.partition_id=ps.partition_id\n" +
                    "    WHERE p.object_id = si.object_id\n" +
                    "        and p.index_id=si.index_id\n" +
                    "    ) AS partition_sums\n" +
                    "/* row compression list by partition */ OUTER APPLY ( SELECT STUFF (\n" +
                    "    (SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))\n" +
                    "    FROM sys.partitions AS p\n" +
                    "    WHERE p.object_id = si.object_id\n" +
                    "        and p.index_id=si.index_id\n" +
                    "        and p.data_compression = 1\n" +
                    "    ORDER BY p.partition_number FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS row_compression_clause ( row_compression_partition_list )\n" +
                    "/* data compression list by partition */ OUTER APPLY ( SELECT STUFF (\n" +
                    "    (SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))\n" +
                    "    FROM sys.partitions AS p\n" +
                    "    WHERE p.object_id = si.object_id\n" +
                    "        and p.index_id=si.index_id\n" +
                    "        and p.data_compression = 2\n" +
                    "    ORDER BY p.partition_number FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,2,'')) AS page_compression_clause ( page_compression_partition_list )\n" +
                    "WHERE \n" +
                    "    si.type IN (0,1,2) /* heap, clustered, nonclustered */\n" +
                    "ORDER BY table_name, si.index_id\n" +
                    "    OPTION (RECOMPILE);\n";
    /**
     * Creates a url string to connect to a server based on a specific host name with a specific port.
     *
     * @param hostName - the specific host name
     * @param port - the specific port
     *
     * @return - the created url string
     */
    public static String createServerConnectionURL(String hostName, int port, String sqlUsername, String sqlPassword) {
        String url = "jdbc:sqlserver://" + hostName + ":" + port + ";";

        if(sqlUsername.equals("") || sqlPassword.equals("")) {
            return url + "integratedSecurity=true";
        }
        return url + "user=" + sqlUsername + "; password=" + sqlPassword;
    }

    /**
     * Creates a url string to connect to a server based on a specific host name with a specific port.
     *
     * @param hostName - the specific host name
     * @param port - the specific port
     *
     * @return - the created url string
     */
    public static String createServerConnectionURL_MultiQuery(String hostName, int port, String sqlUsername, String sqlPassword) {
        String url = "jdbc:sqlserver://" + hostName + ":" + port + ";";

        if(sqlUsername.equals("") || sqlPassword.equals("")) {
            return url + "integratedSecurity=true";
        }
        return url + "allowMultiQueries=true;" + "user=" + sqlUsername + "; password=" + sqlPassword;
    }

    /**
     * Establishes a connection to a server based on a specific hostName and a specific port.
     *
     * @param hostName the name of the host the connection is established to
     * @param port the port the connection is established on
     *
     * @return the established connection, null if any problems occurred.
     */
    public static Connection establishConnection(String hostName, int port, String sqlUsername, String sqlPassword) {
        String url = createServerConnectionURL(hostName, port, sqlUsername, sqlPassword);
        try {
            return DriverManager.getConnection(url);
        } catch (SQLException e) {
            Logger.getLogger().severe("Failed to establish a connection to: " + hostName + ":" + port + ".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return null;
    }

    /**
     * Creates a url string to connect to a server based on a specific hostName, a specific port and a specific
     * databaseName.
     *
     * @param hostName the specific host name to connect to
     * @param port the port the connection is established on
     * @param databaseName the name of the database to connect to
     *
     * @return - the created url string
     */
    public static String createServerDatabaseConnectionURL(String hostName, int port, String databaseName,
                                                           String sqlUsername, String sqlPassword) {
        return createServerConnectionURL(hostName, port, sqlUsername, sqlPassword) + ";database=" + databaseName;
    }

    /**
     *
     * Establishes a connection to a server with an integrated database based on a specific hostName, a specific port
     * and a specific databaseName.
     *
     * @param hostName the name of the host the connection is established to
     * @param port the port the connection is established on
     * @param databaseName the name of the database that is integrated
     *
     * @return the established connection if successful, else null
     */
    public static Connection establishConnection(String hostName, int port, String databaseName, String sqlUsername,
                                                 String sqlPassword) {
        String url = createServerDatabaseConnectionURL(hostName, port, databaseName, sqlUsername, sqlPassword);
        try {
            return DriverManager.getConnection(url);
        } catch (SQLException e) {
            Logger.getLogger().severe("Failed to establish a connection to: " + hostName + ":" + port + "/" + databaseName + ".");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
        return null;
    }

    /**
     *
     * @return the user transfer procedure 1 (i.e., sp_hexadecimal)
     */
    public static String getUserTransferProc1() {
        return USER_TRANSFER_PROC_1;
    }

    /**
     *
     * @return the user transfer procedure 2 (i.e., sp_help_revlogin)
     */
    public static String getUserTransferProc2() {
        return USER_TRANSFER_PROC_2;
    }

    /**
     *
     * @return the user defined types query
     */
    public static String getUserDefinedTypesQuery() {
        return USER_DEFINED_TYPES_QUERY;
    }

    /**
     *
     * @return the fulltext catalog query
     */
    public static String getFulltextCatalogQuery() {
        return FULLTEXT_CATALOG_QUERY;
    }

    /**
     *
     * @return the table indexes query
     */
    public static String getTableIndexesQuery() {
        return TABLE_INDEXES_QUERY;
    }
}
