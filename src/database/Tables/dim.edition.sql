CREATE TABLE [dim].[edition]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[Edition] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[edition] ADD CONSTRAINT [PK_edition] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
