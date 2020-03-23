CREATE TABLE [dim].[productupdatelevel]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[ProductUpdateLevel] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[productupdatelevel] ADD CONSTRAINT [PK_productupdatelevel] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
