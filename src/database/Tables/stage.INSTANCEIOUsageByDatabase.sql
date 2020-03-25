CREATE TABLE [stage].[INSTANCEIOUsageByDatabase]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IORank] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TotalIOPercent] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WriteIOPercent] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TotalIOMB] [int] NULL,
[WriteIOMB] [int] NULL,
[ReadIOPercent] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReadIOMB] [int] NULL
) ON [PRIMARY]
GO
