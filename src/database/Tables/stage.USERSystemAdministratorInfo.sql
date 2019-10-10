CREATE TABLE [stage].[USERSystemAdministratorInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[default_database_name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_disabled] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modify_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
