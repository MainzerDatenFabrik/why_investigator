SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [fact].[scan]
AS
BEGIN
SELECT   datet.datetimeid,
    	datet.MinuteHourDateAsText AS Last_ScanDate,
       --COUNT(datet.DayMonthYearAsText) AS MengeScans,
       countx.ShortDescription,
       fact.value,
       host.Hostname,
       plevel.ProductLevel,
       pmj.ProductMajorVersion,
       -- pmi.ProductLevel AS Expr1,
       pule.productversion,
       pins.name AS InstanceName,
       pedi.Edition
INTO #tempdb
FROM fact.ServerProperties AS fact
    INNER JOIN dim.hostname AS host
        ON host.id = fact.HostId
    INNER JOIN dim.productlevel AS plevel
        ON plevel.id = fact.ProductLevelId
    INNER JOIN dim.productmajorversion AS pmj
        ON pmj.id = fact.ProductMajorVersionId
    INNER JOIN dim.productlevel AS pmi
        ON pmi.id = fact.ProductLevelId
    INNER JOIN dim.productversion AS pule
        ON pule.id = fact.ProductVersionID
    INNER JOIN dim.instance AS pins
        ON pins.id = fact.Instance_id
    INNER JOIN dim.edition AS pedi
        ON pedi.id = fact.EditionId
    INNER JOIN dim.DateTime AS datet
        ON datet.DateTimeID = fact.DateTimeId
    INNER JOIN dim.counter countx
        ON countx.id = fact.counterid
    INNER JOIN dim.projecthashid pro
        ON pro.id = fact.projectHashId

GROUP BY host.Hostname,
         plevel.ProductLevel,
         pmj.ProductMajorVersion,
         pmi.ProductLevel,
         pule.productversion,
         pins.name,
         pedi.Edition,
         countx.ShortDescription,
         fact.value,datet.MinuteHourDateAsText,datet.datetimeid
ORDER BY 1 DESC

DROP TABLE fact.scantab

SELECT datetimeid,Last_ScanDate,Hostname,Productlevel,InstanceName,Edition,LogicalCPUCount,memory_utilization_percentage,CommittedMemoryMB,CommittedTargetMemoryMB,[Count DBs],virtualized,SQLServerMemoryUsageMB,
PhysicalCPUCount,PhysicalMemoryMB,AvailableMemoryMB,SQLServerUpTimehrs,scheduler_count
INTO fact.scantab
FROM #tempdb
PIVOT (SUM(value) FOR ShortDescription IN(LogicalCPUCount,memory_utilization_percentage,CommittedMemoryMB,CommittedTargetMemoryMB,[Count DBs],virtualized,SQLServerMemoryUsageMB,
PhysicalCPUCount,PhysicalMemoryMB,AvailableMemoryMB,SQLServerUpTimehrs,scheduler_count)) AS pvt
ORDER BY 1





SELECT * FROM fact.scantab
WHERE LogicalCPUCount IS NOT NULL
ORDER BY 1 DESC
END
GO
