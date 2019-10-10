CREATE TABLE [stage].[DATABASEComputedColumnsInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Ord] [int] NULL,
[TableName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Computed_Column] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchemaName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
