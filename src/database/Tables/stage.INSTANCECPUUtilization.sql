CREATE TABLE [stage].[INSTANCECPUUtilization]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SQLProcessUtilization15] [int] NULL,
[PhysicalMemoryMB] [int] NULL,
[MaxServerMemory] [int] NULL,
[SQLProcessUtilization10] [int] NULL,
[PageLifeExpectancy] [int] NULL,
[SQLServerMemoryUsageMB] [int] NULL,
[AvailableMemoryMB] [int] NULL,
[SystemMemoryState] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DataSampleTimestamp] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SQLProcessUtilization30] [int] NULL,
[SQLProcessUtilization5] [int] NULL
) ON [PRIMARY]
GO
