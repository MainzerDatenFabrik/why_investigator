CREATE TABLE [dim].[databases]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[Database] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Hostname] [int] NOT NULL,
[db_inst_id] [int] NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[databases] ADD CONSTRAINT [PK_databases] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
