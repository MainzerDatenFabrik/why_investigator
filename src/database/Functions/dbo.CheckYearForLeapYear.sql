SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create FUNCTION [dbo].[CheckYearForLeapYear]
(@p_year SMALLINT)
RETURNS BIT
AS
BEGIN
    DECLARE @p_leap_date SMALLDATETIME
    DECLARE @p_check_day TINYINT
 
    SET @p_leap_date = CONVERT(VARCHAR(4), @p_year) + '0228'
    SET @p_check_day = DATEPART(d, DATEADD(d, 1, @p_leap_date))
    IF (@p_check_day = 29)
        RETURN 1

    RETURN 0  
END
GO
