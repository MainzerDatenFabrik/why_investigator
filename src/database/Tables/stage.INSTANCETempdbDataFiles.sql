CREATE TABLE [stage].[INSTANCETempdbDataFiles]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Local_tcp_port] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Text] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProcessInfo] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LogDate] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
