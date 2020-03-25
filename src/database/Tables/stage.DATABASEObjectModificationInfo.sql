CREATE TABLE [stage].[DATABASEObjectModificationInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_published] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[object_id] [int] NULL,
[principal_id] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent_object_id] [int] NULL,
[is_ms_shipped] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_schema_published] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[schema_id] [int] NULL,
[DBName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_desc] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[create_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modify_date] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
