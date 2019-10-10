CREATE TABLE [fact].[UserBaseInfo]
(
[DateTimeId] [bigint] NOT NULL,
[ProjectHashId] [int] NOT NULL,
[HostId] [int] NOT NULL,
[DatabaseId] [int] NOT NULL,
[CounterId] [int] NOT NULL,
[CounterValue] [int] NOT NULL,
[UserTypeId] [int] NOT NULL,
[DatabaseUsernameId] [int] NOT NULL,
[RoleId] [int] NOT NULL,
[PermissionTypeId] [int] NOT NULL,
[PermissionStateId] [int] NOT NULL,
[ObjectTypeId] [int] NOT NULL,
[ObjectNameId] [int] NOT NULL,
[Port] [int] NOT NULL,
[ServerNameId] [int] NOT NULL
) ON [PRIMARY]
GO
