CREATE TABLE [dim].[hostname]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[Hostname] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[hostname] ADD CONSTRAINT [PK_hostname] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
