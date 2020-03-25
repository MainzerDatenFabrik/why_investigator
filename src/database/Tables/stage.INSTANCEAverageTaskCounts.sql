CREATE TABLE [stage].[INSTANCEAverageTaskCounts]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AvgWorkQueueCount] [int] NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AvgPendingDiskIOCount] [int] NULL,
[AvgRunnableTaskCount] [int] NULL,
[AvgTaskCount] [int] NULL
) ON [PRIMARY]
GO
