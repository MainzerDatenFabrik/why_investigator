CREATE TABLE [dim].[permissiontype]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[permissiontype] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[permissiontype] ADD CONSTRAINT [PK_permissiontype] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
