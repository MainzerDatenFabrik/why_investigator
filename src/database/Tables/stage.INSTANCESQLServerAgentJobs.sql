CREATE TABLE [stage].[INSTANCESQLServerAgentJobs]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SchedEnabled] [int] NULL,
[JobName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[next_run_time] [int] NULL,
[local_tcp_port] [int] NULL,
[JobOwner] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[JobDescription] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[JobEnabled] [int] NULL,
[next_run_date] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notify_level_email] [int] NULL,
[CategoryName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notify_email_operator_id] [int] NULL,
[DateCreated] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
