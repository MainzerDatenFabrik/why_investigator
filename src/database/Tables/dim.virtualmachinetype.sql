CREATE TABLE [dim].[virtualmachinetype]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[VirtualMachineType] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Created] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[virtualmachinetype] ADD CONSTRAINT [PK_virtualmachinetype] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
