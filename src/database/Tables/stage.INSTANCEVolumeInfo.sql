CREATE TABLE [stage].[INSTANCEVolumeInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[logical_volume_name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supports_compression] [int] NULL,
[file_system_type] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AvailableSizeGB] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SpaceFreeInPercent] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[volume_mount_point] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_compressed] [int] NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supports_sparse_files] [int] NULL,
[supports_alternate_streams] [int] NULL,
[TotalSizeGB] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
