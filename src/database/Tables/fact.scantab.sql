CREATE TABLE [fact].[scantab]
(
[datetimeid] [bigint] NOT NULL,
[Last_ScanDate] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Hostname] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Productlevel] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InstanceName] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Edition] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LogicalCPUCount] [bigint] NULL,
[memory_utilization_percentage] [bigint] NULL,
[CommittedMemoryMB] [bigint] NULL,
[CommittedTargetMemoryMB] [bigint] NULL,
[Count DBs] [bigint] NULL,
[virtualized] [bigint] NULL,
[SQLServerMemoryUsageMB] [bigint] NULL,
[PhysicalCPUCount] [bigint] NULL,
[PhysicalMemoryMB] [bigint] NULL,
[AvailableMemoryMB] [bigint] NULL,
[SQLServerUpTimehrs] [bigint] NULL,
[scheduler_count] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [fact].[scantab] ADD CONSTRAINT [FK_scantab_DateTime] FOREIGN KEY ([datetimeid]) REFERENCES [dim].[DateTime] ([DateTimeID])
GO
