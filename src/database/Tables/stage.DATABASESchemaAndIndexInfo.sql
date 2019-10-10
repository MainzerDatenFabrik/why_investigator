CREATE TABLE [stage].[DATABASESchemaAndIndexInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type_Desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IndexUsedForCounts] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchemaName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Rows] [int] NULL
) ON [PRIMARY]
GO
