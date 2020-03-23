CREATE TABLE [dim].[productversion]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[productversion] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[productversion] ADD CONSTRAINT [PK_productversion] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
