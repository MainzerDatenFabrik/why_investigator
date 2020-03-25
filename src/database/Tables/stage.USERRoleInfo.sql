CREATE TABLE [stage].[USERRoleInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bulkadmin] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[processadmin] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[diskadmin] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serveradmin] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[setupadmin] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[securityadmin] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dbcreator] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modify_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sysadmin] [int] NULL
) ON [PRIMARY]
GO
