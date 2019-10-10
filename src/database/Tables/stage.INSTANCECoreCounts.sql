CREATE TABLE [stage].[INSTANCECoreCounts]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Sockets] [int] NULL,
[CoresPerSocket] [int] NULL,
[LogicalProcessorsPerSocket] [int] NULL,
[TotalLogicalProcessors] [int] NULL,
[LicensedLogicalProcessors] [int] NULL,
[ProcessInfo] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LogDate] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
