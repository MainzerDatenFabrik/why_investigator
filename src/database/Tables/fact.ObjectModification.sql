CREATE TABLE [fact].[ObjectModification]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[DatetimeId] [bigint] NOT NULL,
[ProjectHashId] [int] NOT NULL,
[HostnameId] [int] NOT NULL,
[DatabaseId] [int] NOT NULL,
[instance] [int] NOT NULL,
[CounterId] [int] NOT NULL,
[CounterValue] [int] NOT NULL,
[TypeDescriptionId] [int] NOT NULL,
[ObjectNameId] [int] NOT NULL,
[Date] [datetime] NOT NULL,
[SchemaId] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [fact].[ObjectModification] ADD CONSTRAINT [FK_ObjectModification_counter] FOREIGN KEY ([CounterId]) REFERENCES [dim].[counter] ([id])
GO
ALTER TABLE [fact].[ObjectModification] ADD CONSTRAINT [FK_ObjectModification_counter1] FOREIGN KEY ([CounterId]) REFERENCES [dim].[counter] ([id])
GO
ALTER TABLE [fact].[ObjectModification] ADD CONSTRAINT [FK_ObjectModification_DateTime] FOREIGN KEY ([DatetimeId]) REFERENCES [dim].[DateTime] ([DateTimeID])
GO
ALTER TABLE [fact].[ObjectModification] ADD CONSTRAINT [FK_ObjectModification_DateTime1] FOREIGN KEY ([DatetimeId]) REFERENCES [dim].[DateTime] ([DateTimeID])
GO
ALTER TABLE [fact].[ObjectModification] ADD CONSTRAINT [FK_ObjectModification_DateTime2] FOREIGN KEY ([DatetimeId]) REFERENCES [dim].[DateTime] ([DateTimeID])
GO
