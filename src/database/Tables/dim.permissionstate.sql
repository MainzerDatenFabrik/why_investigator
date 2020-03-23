CREATE TABLE [dim].[permissionstate]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[PermissionState] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[permissionstate] ADD CONSTRAINT [PK_permissionstate] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
