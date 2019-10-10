CREATE TABLE [stage].[DATABASEReadsAndWritesInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TableName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SampleSeconds] [int] NULL,
[SampleDays] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Writes] [int] NULL,
[Reads] [int] NULL,
[ReadsAndWrites] [int] NULL
) ON [PRIMARY]
GO
