CREATE TABLE [stage].[USERServerPrincipals]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_fixed_role] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[default_database_name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserType] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_disabled] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[default_language_name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[owning_principal_id] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[principal_id] [int] NULL,
[sid] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LoginType] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Local_tcp_port] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateCreated] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modify_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credential_id] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
