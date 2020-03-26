CREATE TABLE [stage].[INSTANCEIOLatency]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[io_stall_read_ms] [int] NULL,
[physical_name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ResourceGovernorTotalWriteIOLatencyms] [int] NULL,
[avg_io_latency_ms] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[io_stall_write_ms] [int] NULL,
[avg_read_latency_ms] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ResourceGovernorTotalReadIOLatencyms] [int] NULL,
[total_io] [int] NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileSizeMB] [int] NULL,
[num_of_writes] [int] NULL,
[avg_write_latency_ms] [int] NULL,
[type_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[num_of_reads] [int] NULL,
[io_stalls] [int] NULL
) ON [PRIMARY]
GO
