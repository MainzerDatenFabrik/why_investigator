CREATE TABLE [fact].[ServerProperties]
(
[DateTimeId] [bigint] NOT NULL,
[ProjectHashId] [int] NOT NULL,
[HostId] [int] NOT NULL,
[ProductLevelId] [int] NOT NULL,
[ProductMajorVersionId] [int] NOT NULL,
[ProductVersionID] [int] NOT NULL,
[ProductUpdateLevelId] [int] NOT NULL,
[Instance_id] [int] NOT NULL,
[EditionId] [int] NOT NULL,
[CounterID] [int] NOT NULL,
[Value] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [fact].[ServerProperties] ADD CONSTRAINT [FK_ServerProperties_counter] FOREIGN KEY ([CounterID]) REFERENCES [dim].[counter] ([id])
GO
ALTER TABLE [fact].[ServerProperties] ADD CONSTRAINT [FK_ServerProperties_DateTime] FOREIGN KEY ([DateTimeId]) REFERENCES [dim].[DateTime] ([DateTimeID])
GO
