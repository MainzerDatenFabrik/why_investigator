CREATE TABLE [stage].[INSTANCETopWorkerTimeQueries]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowHash] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShortQueryText] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MinElapsedTime] [int] NULL,
[MinWorkerTime] [int] NULL,
[AvgElapsedTime] [int] NULL,
[MaxElapsedTime] [int] NULL,
[MaxWorkerTime] [int] NULL,
[ExecutionCount] [int] NULL,
[CreationTime] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AvgWorkerTime] [int] NULL,
[MinLogicalReads] [int] NULL,
[TotalWorkerTime] [int] NULL,
[HasMissingIndex] [int] NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MaxLogicalReads] [int] NULL,
[AvgLogicalReads] [int] NULL
) ON [PRIMARY]
GO
