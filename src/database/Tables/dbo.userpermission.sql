CREATE TABLE [dbo].[userpermission]
(
[username] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[usertype] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[databaseusername] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[role] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[permissiontype] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[permissionstate] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[objecttype] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[objectname] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[columname] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[databaseName] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fqdn] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_date] [datetime] NULL,
[modify_date] [datetime] NULL
) ON [PRIMARY]
GO
