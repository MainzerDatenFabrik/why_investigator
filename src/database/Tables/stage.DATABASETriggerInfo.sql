CREATE TABLE [stage].[DATABASETriggerInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Type] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TriggerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DB_Name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Triggerscript] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modify_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
