CREATE TABLE [dim].[productlevel]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[ProductLevel] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[productlevel] ADD CONSTRAINT [PK_productlevel] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
