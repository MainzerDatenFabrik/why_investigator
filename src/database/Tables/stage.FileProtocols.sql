CREATE TABLE [stage].[FileProtocols]
(
[datetimeid] [bigint] NOT NULL,
[fqdn] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fileName] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fileHash] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fileGitPath] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[projectHashId] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
