CREATE TABLE [stage].[DatabaseConnectionErrors]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hostName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[databaseName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[port] [int] NULL
) ON [PRIMARY]
GO
