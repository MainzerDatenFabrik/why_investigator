CREATE TABLE [stage].[DATABASEColumnUsageInfo]
(
[datetimeid] [bigint] NULL,
[projectHashId] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Character_Maximum_Length] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Column_Name] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FQDN] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Data_Type] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Prec] [int] NULL,
[ServerName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DBName] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Scale] [int] NULL,
[Count] [int] NULL
) ON [PRIMARY]
GO
