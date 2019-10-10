CREATE TABLE [stage].[INSTANCESQLServerNUMAInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[online_scheduler_count] [int] NULL,
[node_state_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_monitor_state] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [int] NULL,
[memory_node_id] [int] NULL,
[idle_scheduler_count] [int] NULL,
[active_worker_count] [int] NULL,
[processor_group] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avg_load_balance] [int] NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[node_id] [int] NULL
) ON [PRIMARY]
GO
