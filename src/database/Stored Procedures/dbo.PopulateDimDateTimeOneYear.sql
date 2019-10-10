SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[PopulateDimDateTimeOneYear]
(@StartDate DATETIME = NULL)
-- =============================================
-- Procedure Name:		PopulateDimDateTimeOneYear


-- Changed By:			Benedikt Schackenberg					 

-- Description:			Populates TimeDim with one Year of Data

-- Context:				
-- Purpose: 

-- Dependencies:		Function: dbo.CheckYearForLeapYear
--						
-- Execution Example:	

-- To create data for 2008 execute the following statement
-- EXEC [dbo].[PopulateDimDateTimeOneYear] '2018-12-31 23:59:59.997' 
-- =============================================

AS

--declare @StartDate datetime
--SET @StartDate = '20090101 00:00'

Set nocount on;


--truncate Table dim.datetime;

--Get the Startday:   
if @StartDate  is null
  	Select @StartDate = Max(DateAndTimeAsDate)  from Dim.DateTime;
	Select @StartDate ;
    
--    return 
    --    DECLARE  @StartDate DateTime
    --SET @StartDate = '2007-12-31 23:59:59.997'
  IF OBJECT_ID('dbo.Tally') IS NOT NULL         
	DROP TABLE dbo.Tally;

 

-- Build 1440 (minutes of one day) ids to cross join 
-- use 365 days for year 
-- use 366 days for leap year
	
--SELECT 365*1440
--SELECT 366*1440

DECLARE @ISLeapYear INT
SET @ISLeapYear = (SELECT dbo.CheckYearForLeapYear(YEAR(@StartDate)+1))

	IF(@ISLeapYear=0)
	BEGIN
		SELECT TOP 525600
		IDENTITY(INT,1,1) as Id
		Into 
			dbo.Tally    

		FROM Master.dbo.SysColumns sc1, 
			   Master.dbo.SysColumns sc2
		;   
	END

	IF(@ISLeapYear=1)
	BEGIN
		SELECT TOP 527040
		IDENTITY(INT,1,1) as Id
		Into 
			dbo.Tally    

		FROM Master.dbo.SysColumns sc1, 
			   Master.dbo.SysColumns sc2
		;   
	END


 ALTER TABLE dbo.Tally    
	ADD CONSTRAINT PK_Tally_id         
		PRIMARY KEY CLUSTERED (id) WITH FILLFACTOR = 100
		;

   
-- Build a Monthnames Table to join
  IF OBJECT_ID('dbo.MonthNames') IS NOT NULL         
	DROP TABLE dbo.MonthNames;


	Create Table dbo.MonthNames
		( id int
		, [MonthName] varchar(255)
		);

	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(1 , 'Januar') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(2 , 'Februar') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(3 , 'März') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(4 , 'April') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(5 , 'Mai') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(6 , 'Juni') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(7 , 'Juli') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(8 , 'August'); 
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(9 , 'September'); 
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(10 , 'Oktober') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(11 , 'November') ;
	Insert dbo.MonthNames	( id	, [MonthName]	)  Values	(12 , 'Dezember') ;
		

-- Build a Daynames Table to join
  IF OBJECT_ID('dbo.DayNames') IS NOT NULL         
	DROP TABLE dbo.DayNames;
  


	Create Table dbo.DayNames
		( id int
		, [DayName] varchar(255)
		);

	Insert dbo.DayNames	( id	, [DayName]	)  Values	(1 , 'Montag') ;
	Insert dbo.DayNames	( id	, [DayName]	)  Values	(2 , 'Dienstag'); 
	Insert dbo.DayNames	( id	, [DayName]	)  Values	(3 , 'Mittwoch') ;
	Insert dbo.DayNames	( id	, [DayName]	)  Values	(4 , 'Donnerstag'); 
	Insert dbo.DayNames	( id	, [DayName]	)  Values	(5 , 'Freitag') ;
	Insert dbo.DayNames	( id	, [DayName]	)  Values	(6 , 'Samstag') ;
	Insert dbo.DayNames	( id	, [DayName]	)  Values	(7 , 'Sonntag') ;


   Set nocount off

 
Select getdate() as StartNow;  
-- Join and fill the Datetime Dimension

    INSERT dim.datetime
    SELECT 
--		dateadd(n, id , @StartDate ) as DateAndTimeAsDate
	 CAST(CONVERT(VARCHAR, DATEADD(n, t.id , @StartDate ) ,112)+ SUBSTRING(REPLACE(CONVERT(VARCHAR, DATEADD(n, t.id , @StartDate ) ,108),':','') , 1, 4) AS BIGINT) 
	 AS Datetimetid
	,CAST(CONVERT(VARCHAR, DATEADD(n, t.id , @StartDate ) ,112) AS BIGINT) 
	 AS DateId
    ,CAST(YEAR(DATEADD(n, t.id , @StartDate )  ) AS BIGINT) 
     AS YearId
	,CAST( SUBSTRING(CONVERT(VARCHAR, DATEADD(n,t.id , @StartDate ) ,112), 1, 6) AS BIGINT) 
	 AS MonthYearId
    ,CAST(MONTH(DATEADD(n,t.id , @StartDate )  ) AS BIGINT) 
     AS MonthId
    ,CAST(CAST(YEAR(DATEADD(n, t.id , @StartDate ))AS VARCHAR(4))	+	 CAST(DATEPART(wk,(DATEADD(n,t.id , @StartDate )))AS VARCHAR(2)) AS BIGINT) 
     AS WeekYearId
    ,CAST(DATEPART(wk,(DATEADD(n,t.id , @StartDate ))) AS BIGINT) 
     AS WeekId
    ,CAST( SUBSTRING(CONVERT(VARCHAR, DATEADD(n,t.id , @StartDate ) ,112), 5, 4) AS BIGINT) 
     AS DayMonthId
    ,CAST( DATEPART(d, DATEADD(n,t.id , @StartDate ) ) AS BIGINT ) 
     AS DayId
    ,CAST( DATEPART(dw, DATEADD(n,t.id , @StartDate ) ) AS BIGINT) 
     AS DayOfWeekId
	,CAST(CONVERT(VARCHAR, DATEADD(n,t.id , @StartDate ) ,112)+ SUBSTRING(REPLACE(CONVERT(VARCHAR, DATEADD(n,t.id , @StartDate ) ,108),':','') , 1, 2)  AS BIGINT) 
	 AS HourDateId
    ,CAST(DATEPART(hh, DATEADD(n,t.id , @StartDate ) ) AS BIGINT) 
     AS HourId
	,CAST(CONVERT(VARCHAR, DATEADD(n,t.id , @StartDate ) ,112)+ SUBSTRING(REPLACE(CONVERT(VARCHAR, DATEADD(n,t.id , @StartDate ) ,108),':','') , 1, 4)  AS BIGINT) 
	 AS MinuteHourDateId --change MinuteDateId
    ,CAST( DATEPART(n, DATEADD(n,t.id , @StartDate))  AS BIGINT) 
     AS MinuteId --change MinuteHourId
    ,CAST( m.[MonthName] + ' ' +  CAST(YEAR(DATEADD(n, t.id , @StartDate )  ) AS VARCHAR) AS VARCHAR) 
     AS MonthYearAsText
    ,CAST( m.[MonthName] AS VARCHAR) 
     AS MonthAsText
	,CAST('KW' + RIGHT('0' + CONVERT(VARCHAR(2),DATEPART(wk,DATEADD(n, t.id , @StartDate ))),2) + ' ' + CONVERT(VARCHAR(4),YEAR(DATEADD(n, t.id , @StartDate )))  AS VARCHAR) 
	 AS WeekYearAsText --change WeekDateAsText
	,CAST('KW' + RIGHT('0' + CONVERT(VARCHAR(2),DATEPART(wk,DATEADD(n, t.id , @StartDate ))),2)  AS VARCHAR) 
	 AS WeekAsText
	,CAST(CONVERT(VARCHAR(2),DAY(DATEADD(n, t.id , @StartDate ))) + '. ' + m.[MonthName] + ' ' + CONVERT(VARCHAR(4),YEAR(DATEADD(n, t.id , @StartDate )))  AS VARCHAR) 
	 AS DayMonthYearAsText
	,CAST(CONVERT(VARCHAR(2),DAY(DATEADD(n, t.id , @StartDate ))) + '. ' + m.[MonthName]   AS VARCHAR) 
	 AS DayMonthAsText
	,CAST(CONVERT(VARCHAR(2),DAY(DATEADD(n, t.id , @StartDate ))) + '. '  AS VARCHAR) 
	 AS DayAsText
	,CAST(d.[DayName]  AS VARCHAR) 
	 AS DayOfWeekAsText
    ,CAST(CONVERT(VARCHAR(2),DAY(DATEADD(n, t.id , @StartDate ))) + '.' + CONVERT(VARCHAR(2),MONTH(DATEADD(n, t.id , @StartDate ))) + '.' + CONVERT(VARCHAR(4),YEAR(DATEADD(n, t.id , @StartDate ))) + ' ' + CONVERT(VARCHAR(2), DATEPART(hh, DATEADD(n, t.id , @StartDate ))) + ' Uhr'  AS VARCHAR) 
     AS HourDateAsText
    ,CAST(CONVERT(VARCHAR(2), DATEPART(hh, DATEADD(n, t.id , @StartDate ))) + 'Uhr'  AS VARCHAR) 
     AS HourAsText
    ,CAST(CONVERT(VARCHAR(2),DAY(DATEADD(n, t.id , @StartDate ))) + '.' + CONVERT(VARCHAR(2),MONTH(DATEADD(n, t.id , @StartDate ))) + '.' + CONVERT(VARCHAR(4),YEAR(DATEADD(n, t.id , @StartDate ))) + ' ' + SUBSTRING(CONVERT(VARCHAR, DATEADD(n, t.id , @StartDate ) ,108) , 1, 5)  + ' Uhr'  AS VARCHAR) 
     AS MinuteHourDateAsText --change MinuteDateAsText
	,CAST(SUBSTRING(CONVERT(VARCHAR, DATEADD(n, t.id , @StartDate ) ,108) , 1, 5)  AS VARCHAR) 
	 AS MinuteHourAsText
	,CONVERT(DATETIME, CAST(CONVERT(VARCHAR, DATEADD(n, t.id , @StartDate ) ,112) AS VARCHAR) )   
	 AS StartOfDayASDate
	,DATEADD(n, t.id , @StartDate )  
	 AS DateAndTimeAsDate
	--into #mytemp	
FROM              
	dbo.Tally t
	   INNER JOIN dbo.MonthNames m 
	              ON m.id = MONTH(DATEADD(n, t.id , @StartDate )) 
	   INNER JOIN dbo.DayNames d 
	              ON d.id = DATEPART(dw, DATEADD(n, t.id , @StartDate )) 
		;
		
SELECT GETDATE() AS Ended;		
		
		
IF OBJECT_ID('dbo.MonthNames') IS NOT NULL         
	DROP TABLE dbo.MonthNames;
		
IF OBJECT_ID('dbo.Tally') IS NOT NULL         
	DROP TABLE dbo.Tally;

IF OBJECT_ID('dbo.DayNames') IS NOT NULL         
	DROP TABLE dbo.DayNames;


	--	Select * from dim.datetime;

--select * from #mytemp
----order by 1
--where
--Datetimetid=200812310000

--drop table #mytemp
GO
