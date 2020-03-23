CREATE TABLE [dim].[projecthashid]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[projectHashId] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[projecthashid] ADD CONSTRAINT [PK_projecthashid] PRIMARY KEY NONCLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ClusteredIndex-20190821-114912] ON [dim].[projecthashid] ([Created]) ON [PRIMARY]
GO
