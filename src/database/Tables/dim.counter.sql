CREATE TABLE [dim].[counter]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[datetimeid] [bigint] NULL,
[ShortDescription] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LongDescription] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Unit] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[counter] ADD CONSTRAINT [PK_counter] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
