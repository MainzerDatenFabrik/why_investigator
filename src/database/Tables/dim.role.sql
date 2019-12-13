CREATE TABLE [dim].[role]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[Role] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[host_id] [int] NOT NULL,
[db_id] [int] NOT NULL,
[db_inst_id] [int] NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[role] ADD CONSTRAINT [PK_role] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
