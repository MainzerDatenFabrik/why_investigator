SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[fn_generate_bigint](@datetime datetime)

returns bigint

as

begin

return (

    select (

           DATEPART(year, @datetime) * 10000000000 +

           DATEPART(month, @datetime) * 100000000 +

           DATEPART(day, @datetime) * 1000000 +

           DATEPART(hour, @datetime) * 10000 +

           DATEPART(minute, @datetime) * 100 +

           DATEPART(second, @datetime)

           ) * 1000 +

           DATEPART(millisecond, @datetime)

)

end
GO
