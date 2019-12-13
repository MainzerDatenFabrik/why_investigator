CREATE TABLE [dim].[instance]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[name] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[host_id] [int] NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[instance] ADD CONSTRAINT [PK_instance] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
