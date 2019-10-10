CREATE TABLE [dbo].[sysdiagrams]
(
[name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[principal_id] [int] NULL,
[diagram_id] [int] NULL,
[version] [int] NULL,
[definition] [varbinary] (1) NULL
) ON [PRIMARY]
GO
