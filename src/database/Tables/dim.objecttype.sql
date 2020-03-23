CREATE TABLE [dim].[objecttype]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[Type] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[objecttype] ADD CONSTRAINT [PK_objecttype] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
