CREATE TABLE [stage].[INSTANCESQLServerServicesInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[service_account] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process_id] [int] NULL,
[status_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [int] NULL,
[startup_type_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cluster_nodename] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_startup_time] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[filename] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[servicename] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_clustered] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
