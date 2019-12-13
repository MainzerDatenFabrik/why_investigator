CREATE TABLE [dim].[productmajorversion]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[ProductMajorVersion] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[productmajorversion] ADD CONSTRAINT [PK_productmajorversion] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
