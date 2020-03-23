CREATE TABLE [dim].[serviceaccounts]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[Created] [bigint] NOT NULL,
[service_Account] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[host_id] [int] NOT NULL,
[db_instance_id] [int] NOT NULL,
[service_name] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[serviceaccounts] ADD CONSTRAINT [PK_serviceaccounts] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
