CREATE TABLE [dim].[databaseusername]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[DatabaseUserName] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[host_id] [int] NOT NULL,
[instance_id] [int] NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[databaseusername] ADD CONSTRAINT [PK_databaseusername] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
