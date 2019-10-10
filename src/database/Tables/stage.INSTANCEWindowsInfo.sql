CREATE TABLE [stage].[INSTANCEWindowsInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[windows_sku] [int] NULL,
[os_language_version] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [int] NULL,
[windows_release] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[windows_service_pack_level] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
