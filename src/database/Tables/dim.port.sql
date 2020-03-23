CREATE TABLE [dim].[port]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[port] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[host_id] [int] NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[port] ADD CONSTRAINT [PK_host] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
