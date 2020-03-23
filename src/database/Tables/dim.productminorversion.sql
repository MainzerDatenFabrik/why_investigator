CREATE TABLE [dim].[productminorversion]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[ProductMinorVersion] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[productminorversion] ADD CONSTRAINT [PK_productminorversion] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
