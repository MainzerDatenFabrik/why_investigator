IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'MADAFA\benedikt')
CREATE LOGIN [MADAFA\benedikt] FROM WINDOWS
GO
CREATE USER [MADAFA\benedikt] FOR LOGIN [MADAFA\benedikt]
GO
