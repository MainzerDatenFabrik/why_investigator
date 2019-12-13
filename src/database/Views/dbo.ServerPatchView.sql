SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ServerPatchView]
AS
SELECT DISTINCT
       t1.created / 10000 AS [TimeStamp],
       t1.SCANDATE,
       t1.hostname,
       t1.InstanceName,
       t1.Produktversion,
       COUNT(t2.Menge) AS UserDatabases
FROM 
(
 SELECT proj.created,
       dd.DayMonthYearAsText AS SCANDATE,
       host.hostname,
       ins.name AS [InstanceName],
       prv.productversion AS ProduktVersion,
       proj.projecthashid
FROM [why_investigator_stage].[fact].[ServerProperties] fact
    INNER JOIN dim.projecthashid proj
        ON proj.[id] = fact.[ProjectHashId]
    INNER JOIN dim.hostname host
        ON host.id = fact.hostid
    INNER JOIN dim.counter fcount
        ON fcount.id = fact.counterid
    INNER JOIN dim.productversion prv
        ON prv.id = fact.productversionid
    INNER JOIN dim.instance ins
        ON ins.id = fact.Instance_id
    INNER JOIN dim.datetime dd
        ON dd.datetimeid = (proj.created)
GROUP BY proj.projecthashid,
         host.hostname,
         ins.name,
         prv.productversion,
         dd.DayMonthYearAsText,
         proj.projecthashid,
         proj.created
)
 t1
    INNER JOIN (
		  SELECT [datetimeid],
       [projectHashId],
       servername,
       1 AS Menge

FROM [why_investigator_stage].[stage].[DATABASEBLOBInfo]
GROUP BY [datetimeid],
         [projectHashId],
         servername,
         dbname
	) t2
        ON t1.projecthashid = t2.projecthashid
           AND t1.instancename = t2.servername
GROUP BY t1.SCANDATE,
         t1.hostname,
         t1.InstanceName,
         t1.Produktversion,
         t2.projecthashid,
         t2.servername,
         t1.created / 10000

GO
