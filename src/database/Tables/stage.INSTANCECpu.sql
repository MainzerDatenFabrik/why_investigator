CREATE TABLE [stage].[INSTANCECpu]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_id] [int] NULL,
[SQLServer_CPU_Utilization] [int] NULL,
[System_Idle_Process] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [int] NULL,
[Event_Time] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Other_Process_CPU_Utilization] [int] NULL
) ON [PRIMARY]
GO
