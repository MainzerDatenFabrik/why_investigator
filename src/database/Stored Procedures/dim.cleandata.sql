SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dim].[cleandata] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 		TRUNCATE TABLE dim.databases
		TRUNCATE TABLE dim.databaseusername
		TRUNCATE TABLE dim.hostname	
		TRUNCATE TABLE dim.instance
		TRUNCATE TABLE dim.objectname
		TRUNCATE TABLE dim.objecttype
		TRUNCATE TABLE dim.permissionstate
		TRUNCATE TABLE dim.permissiontype
		TRUNCATE TABLE dim.port
		TRUNCATE TABLE dim.projecthashid
		TRUNCATE TABLE dim.role
		TRUNCATE TABLE dim.usertype
		TRUNCATE TABLE fact.UserBaseInfo
		TRUNCATE TABLE dbo.log
END
GO
