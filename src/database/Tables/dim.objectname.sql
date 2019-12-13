CREATE TABLE [dim].[objectname]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[Name] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[host_id] [int] NOT NULL,
[db_id] [int] NOT NULL,
[db_instance_id] [int] NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[objectname] ADD CONSTRAINT [PK_objectname] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
