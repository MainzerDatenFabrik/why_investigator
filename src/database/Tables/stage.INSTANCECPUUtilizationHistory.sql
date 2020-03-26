CREATE TABLE [stage].[INSTANCECPUUtilizationHistory]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EventTime] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SystemIdleProcess] [int] NULL,
[SQLServerProcessCPUUtilization] [int] NULL,
[OtherProcessCPUUtilization] [int] NULL
) ON [PRIMARY]
GO
