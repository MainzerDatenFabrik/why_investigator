CREATE TABLE [stage].[INSTANCEConfigurationValues]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value_in_use] [int] NULL,
[is_advanced] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [int] NULL,
[name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_dynamic] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[maximum] [int] NULL,
[description] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value] [int] NULL,
[minimum] [int] NULL
) ON [PRIMARY]
GO
