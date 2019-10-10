CREATE TABLE [stage].[INSTANCEHardwareInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PhysicalMemoryMB] [int] NULL,
[scheduler_count] [int] NULL,
[LogicalCPUCount] [int] NULL,
[SQLServerUpTimehrs] [int] NULL,
[SQLServerStartTime] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VirtualMachineType] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Local_tcp_port] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaxWorkersCount] [int] NULL,
[CommittedTargetMemoryMB] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AffinityType] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CommittedMemoryMB] [int] NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HyperthreadRatio] [int] NULL,
[PhysicalCPUCount] [int] NULL
) ON [PRIMARY]
GO
