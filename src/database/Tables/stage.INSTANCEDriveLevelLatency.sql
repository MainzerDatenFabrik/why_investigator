CREATE TABLE [stage].[INSTANCEDriveLevelLatency]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VolumeMountPoint] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WriteLatency] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AvgBytesTransfer] [int] NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Drive] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReadLatency] [int] NULL,
[OverallLatency] [int] NULL,
[AvgBytesRead] [int] NULL,
[AvgBytesWrite] [int] NULL
) ON [PRIMARY]
GO
