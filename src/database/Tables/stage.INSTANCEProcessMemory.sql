CREATE TABLE [stage].[INSTANCEProcessMemory]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[memory_utilization_percentage] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SQLServerLargePagesAllocationMB] [int] NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SQLServerLockedPagesAllocationMB] [int] NULL,
[process_virtual_memory_low] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[local_tcp_port] [int] NULL,
[available_commit_limit_kb] [int] NULL,
[SQLServerMemoryUsageMB] [int] NULL,
[process_physical_memory_low] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fault_count] [int] NULL
) ON [PRIMARY]
GO
