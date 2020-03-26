CREATE TABLE [stage].[INSTANCELastBackupByDatabase]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastFullBackup] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastDifferentialBackup] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastLogBackup] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LogReuseWaitDesc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [int] NULL,
[DatabaseName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RecoveryModel] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
