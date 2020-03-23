CREATE TABLE [dim].[usertype]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[UserType] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[usertype] ADD CONSTRAINT [PK_usertype] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
