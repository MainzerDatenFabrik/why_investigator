CREATE TABLE [stage].[INSTANCEDatabaseFilenamesAndPaths]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[physical_name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TotalSizeinMB] [int] NULL,
[local_tcp_port] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_percent_growth] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[file_id] [int] NULL,
[state_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[growth] [int] NULL,
[type_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GrowthinMB] [int] NULL
) ON [PRIMARY]
GO
