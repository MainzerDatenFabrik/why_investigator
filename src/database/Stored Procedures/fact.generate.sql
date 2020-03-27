SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Benedikt Schackenberg
-- Create date: 07.04.2019
-- Description:	<Description,,>
-- exec [fact].[generate] 
-- =============================================
CREATE PROCEDURE [fact].[generate]
AS
BEGIN

    DECLARE @Starzeit AS DATETIME2;
    DECLARE @EndZeit AS DATETIME2;
    SET NOCOUNT ON;
    SET @Starzeit = GETDATE();

    UPDATE [stage].[USERUsersInfo]
    SET [role] = 'NN'
    WHERE [role] IS NULL;

    UPDATE [stage].[USERUsersInfo]
    SET [objecttype] = 'NN'
    WHERE [objecttype] IS NULL;


    UPDATE [stage].[USERUsersInfo]
    SET [objectname] = 'NN'
    WHERE [objectname] IS NULL;

    UPDATE [stage].[USERUsersInfo]
    SET [permissionstate] = 'NN'
    WHERE [permissionstate] IS NULL;

    UPDATE [stage].[USERUsersInfo]
    SET [permissiontype] = 'NN'
    WHERE [permissiontype] IS NULL;

    UPDATE [stage].[INSTANCEServerProperties]
    SET [ProductUpdateLevel] = 'NN'
    WHERE [ProductUpdateLevel] IS NULL;



    PRINT 'Hostname Verarbeitung Start';




    INSERT INTO [dim].[hostname]
    (
        [Hostname],
        [Created]
    )
    SELECT DISTINCT
           LOWER(base.[FQDN]) AS fqdn,
           MIN(base.datetimeid) AS DatetimeID
    FROM [stage].[CUSTOMServerDatabasesOverview] base
    WHERE base.FQDN IS NOT NULL
          AND base.FQDN NOT IN
              (
                  SELECT DISTINCT Hostname FROM dim.hostname
              )
    GROUP BY base.FQDN;

    PRINT 'Hostname Verarbeitung beendet';

    PRINT 'ProjektHASHID Start';

    INSERT INTO [dim].[projecthashid]
    (
        [projectHashId],
        [Created]
    )
    SELECT DISTINCT
           base.[projectHashId],
           MIN(base.datetimeid) AS DatetimeID
    FROM stage.[FileProtocols] base
    WHERE base.projectHashId IS NOT NULL
          AND base.[projectHashId] NOT IN
              (
                  SELECT DISTINCT projectHashId FROM [dim].[projecthashid]
              )
    GROUP BY projectHashId;

    PRINT 'ProjektHASHID Ende';

    PRINT 'Datenbanken Start';

    INSERT INTO [dim].[databases]
    (
        [Created],
        [Database],
        [Hostname],
        [db_inst_id]
    )
    SELECT MIN(base.[datetimeid]) AS datetimeid,
           base.[databaseName] AS name,
           host.id AS servername,
           dimins.id
    FROM stage.[USERUsersInfo] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
        INNER JOIN dim.instance dimins
            ON dimins.[name] = base.servername
    WHERE base.databaseName IS NOT NULL
          AND NOT EXISTS
    (
        SELECT [database]
        FROM [dim].[databases]
        WHERE [database] = base.[databaseName]
              AND Hostname = host.id
              AND db_inst_id = dimins.id
    )
    GROUP BY [databaseName],
             [fqdn],
             host.id,
             dimins.[id];

    PRINT 'Datenbanken Ende';


    PRINT 'USERTYPE Start';
    INSERT INTO [dim].[usertype]
    (
        [UserType],
        [Created]
    )
    SELECT LOWER(   CASE
                        WHEN usertype IS NULL THEN
                            'NN'
                        ELSE
                            usertype
                    END
                ) AS usertype,
           MIN(datetimeid) AS datetimeid
    FROM stage.[USERUsersInfo]
    WHERE LOWER(usertype) NOT IN
          (
              SELECT UserType FROM dim.usertype
          )
    GROUP BY usertype;

    PRINT 'USERTYPE Ende';
    PRINT 'Instance Start';
    INSERT INTO [dim].[instance]
    (
        [name],
        [host_id],
        [Created]
    )
    SELECT base.[servername] AS name,
           host.id,
           MIN(base.[datetimeid]) AS datetimeid
    FROM stage.[USERUsersInfo] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
    WHERE base.servername IS NOT NULL
          AND NOT EXISTS
    (
        SELECT *
        FROM [dim].[instance]
        WHERE [name] = base.[servername]
              AND [host_id] = host.id
    )
    GROUP BY [servername],
             host.id;
    PRINT 'Instance Ende';

    PRINT 'Databaseusername start';
    INSERT INTO [dim].[databaseusername]
    (
        [DatabaseUserName],
        [host_id],
        [instance_id],
        [Created]
    )
    SELECT base.[databaseusername] AS name,
           host.id AS servername,
           diminstance.id,
           MIN(base.[datetimeid]) AS datetimeid
    FROM stage.[USERUsersInfo] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
        INNER JOIN dim.instance diminstance
            ON base.servername = diminstance.name
    WHERE base.databaseusername IS NOT NULL
          AND NOT EXISTS
    (
        SELECT *
        FROM [dim].[databaseusername]
        WHERE [DatabaseUserName] = base.[databaseusername]
              AND host_id = host.id
              AND instance_id = diminstance.id
    )
    GROUP BY [databaseusername],
             [fqdn],
             host.id,
             diminstance.id;

    PRINT 'databaseusername Ende';


    PRINT 'role start';
    INSERT INTO [dim].[role]
    (
        [Role],
        [host_id],
        [db_id],
        [db_inst_id],
        [Created]
    )
    SELECT CASE
               WHEN base.role IS NULL THEN
                   'NN'
               ELSE
                   base.role
           END AS [role],
           host.id AS servername,
           dimdb.id,
           diminstance.id,
           MIN(base.[datetimeid]) AS datetimeid
    FROM stage.[USERUsersInfo] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
        INNER JOIN dim.databases dimdb
            ON dimdb.[Database] = base.databaseName
        INNER JOIN dim.instance diminstance
            ON base.servername = diminstance.name
    WHERE NOT EXISTS
    (
        SELECT *
        FROM [dim].[role] r
        WHERE [Role] = base.[role]
              AND host_id = host.id
              AND db_id = dimdb.id
    )
    GROUP BY [role],
             [fqdn],
             host.id,
             dimdb.id,
             diminstance.id;

    PRINT 'Role Ende';

    PRINT 'Permissiotype Start';

    INSERT INTO [dim].[permissiontype]
    (
        [permissiontype],
        [Created]
    )
    SELECT LOWER(   CASE
                        WHEN permissiontype IS NULL THEN
                            'NN'
                        ELSE
                            permissiontype
                    END
                ) AS permissiontype,
           MIN(datetimeid) AS datetimeid
    FROM stage.[USERUsersInfo] base
    WHERE base.permissiontype NOT IN
          (
              SELECT DISTINCT permissiontype FROM [dim].[permissiontype]
          )
    GROUP BY base.permissiontype;

    PRINT 'Permissiotype Ende';

    PRINT 'Permisisonstate Start';

    INSERT INTO [dim].[permissionstate]
    (
        [PermissionState],
        [Created]
    )
    SELECT LOWER(   CASE
                        WHEN permissionstate IS NULL THEN
                            'NN'
                        ELSE
                            permissionstate
                    END
                ) AS permissionstate,
           MIN(datetimeid) AS datetimeid
    FROM stage.[USERUsersInfo] base
    WHERE base.permissionstate NOT IN
          (
              SELECT DISTINCT PermissionState FROM [dim].[permissionstate]
          )
    GROUP BY base.permissionstate;

    PRINT 'Permisisonstate Ende';


    PRINT '[objecttype] Start';

	-- USERUserInfo object types

    INSERT INTO [dim].[objecttype]
    (
        [Type],
        [Created]
    )
    SELECT LOWER(   CASE
                        WHEN objecttype IS NULL THEN
                            'NN'
                        ELSE
                            objecttype
                    END
                ) AS objecttype,
           MIN(datetimeid) AS datetimeid
    FROM stage.[USERUsersInfo] base
    WHERE base.objecttype NOT IN
          (
              SELECT DISTINCT Type FROM [dim].[objecttype]
          )
    GROUP BY base.objecttype;

	-- DATABASEObjectModification object types

	INSERT INTO [dim].[objecttype]
    (
        [Type],
        [Created]
    )
    SELECT LOWER(   CASE
                        WHEN base.type_desc IS NULL THEN
                            'NN'
                        ELSE
                            base.type_desc
                    END
                ) AS objecttype,
           MIN(datetimeid) AS datetimeid
    FROM stage.[DATABASEObjectModificationInfo] base
    WHERE base.type_desc NOT IN
          (
              SELECT DISTINCT Type FROM [dim].[objecttype]
          )
    GROUP BY base.type_desc;

    PRINT '[objecttype] Ende';


    PRINT '[objectname] Start';

	-- USERUsersInfo object names

    INSERT INTO [dim].[objectname]
    (
        [Name],
        [host_id],
        [db_id],
        db_instance_id,
        [Created]
    )
    SELECT base.[objectname] AS name,
           host.id,
           db.id,
           ins.id,
           MIN(base.[datetimeid]) AS datetimeid

    -- MIN(base.[datetimeid]) AS datetimeid
    FROM stage.[USERUsersInfo] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
        INNER JOIN dim.databases db
            ON db.Hostname = host.id
               AND db.[Database] = base.databaseName
        INNER JOIN dim.instance ins
            ON ins.name = base.servername
    WHERE base.objectname IS NOT NULL
          AND NOT EXISTS
    (
        SELECT *
        FROM [dim].[objectname]
        WHERE [Name] = base.[objectname]
              AND [host_id] = host.id
              AND [db_id] = db.id
              AND [db_instance_id] = ins.id
    )
    GROUP BY [objectname],
             host.id,
             db.id,
             ins.id;

	-- DATABASEObjectModification object names

	INSERT INTO [dim].[objectname]
    (
        [Name],
        [host_id],
        [db_id],
        db_instance_id,
        [Created]
    )
    SELECT base.name AS name,
           host.id,
           db.id,
           ins.id,
           MIN(base.[datetimeid]) AS datetimeid

    -- MIN(base.[datetimeid]) AS datetimeid
    FROM stage.DATABASEObjectModificationInfo base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
        INNER JOIN dim.databases db
            ON db.Hostname = host.id
               AND db.[Database] = base.name
        INNER JOIN dim.instance ins
            ON ins.name = base.servername
    WHERE base.name IS NOT NULL
          AND NOT EXISTS
    (
        SELECT *
        FROM [dim].[objectname]
        WHERE [Name] = base.name
              AND [host_id] = host.id
              AND [db_id] = db.id
              AND [db_instance_id] = ins.id
    )
    GROUP BY base.name,
             host.id,
             db.id,
             ins.id;

    PRINT '[objectname] Ende';



    PRINT 'Port Start';

    INSERT INTO [dim].[port]
    (
        [port],
        [host_id],
        [Created]
    )
    SELECT base.[portListen] AS name,
           host.id,
           MIN(base.[datetimeid]) AS datetimeid

    -- MIN(base.[datetimeid]) AS datetimeid
    FROM stage.[USERUsersInfo] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
    WHERE base.portListen IS NOT NULL
          AND NOT EXISTS
    (
        SELECT *
        FROM [dim].[port]
        WHERE [port] = base.[portListen]
              AND [host_id] = host.id
    )
    GROUP BY [portListen],
             host.id;

    PRINT 'Port Ende';

    TRUNCATE TABLE [fact].[UserBaseInfo];

    PRINT 'FaktenTab Userinfo Start / Create';
    INSERT INTO [fact].[UserBaseInfo]
    (
        [DateTimeId],
        [ProjectHashId],
        [HostId],
        [DatabaseId],
        [CounterId],
        [CounterValue],
        [UserTypeId],
        [DatabaseUsernameId],
        [RoleId],
        [PermissionTypeId],
        [PermissionStateId],
        [ObjectTypeId],
        [ObjectNameId],
        [Port],
        [ServerNameId]
    )
    SELECT LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, create_date, 110)), 12) AS datetimeid,
           dimhasid.id,
           host.id,
           db.id,
           '4' AS CounterID,
           1 AS [CounterValue],
           dimusertype.id,
           dimuserdb.id,
           dimrole.id,
           dimpermtype.id,
           dimpermstate.id,
           dimobjectype.id,
           dimobjectname.id,
           dimport.id,
           dimrole.db_inst_id
    FROM stage.[USERUsersInfo] base
        INNER JOIN dim.projecthashid dimhasid
            ON dimhasid.projectHashId = base.projectHashId
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
        INNER JOIN dim.databases db
            ON db.Hostname = host.id
               AND db.[Database] = base.databaseName
        INNER JOIN dim.usertype dimusertype
            ON dimusertype.UserType = base.usertype
        INNER JOIN dim.instance diminstance
            ON diminstance.name = base.servername
               AND diminstance.host_id = host.id
        INNER JOIN dim.databaseusername dimuserdb
            ON dimuserdb.DatabaseUserName = base.databaseusername
               AND dimuserdb.[host_id] = host.id
               AND dimuserdb.[instance_id] = diminstance.id
        INNER JOIN dim.role dimrole
            ON dimrole.Role = base.role
               AND dimrole.[host_id] = host.id
               AND dimrole.[db_id] = db.id
               AND dimrole.db_inst_id = diminstance.id
        INNER JOIN dim.permissiontype dimpermtype
            ON dimpermtype.permissiontype = base.permissiontype
        INNER JOIN dim.permissionstate dimpermstate
            ON dimpermstate.PermissionState = base.permissionstate
        INNER JOIN dim.objecttype dimobjectype
            ON dimobjectype.Type = base.objecttype
        INNER JOIN dim.port dimport
            ON dimport.port = base.portListen
               AND dimport.[host_id] = host.id
        INNER JOIN dim.objectname dimobjectname
            ON db.id = dimobjectname.[db_id]
               AND host.id = dimobjectname.[host_id]
               AND dimobjectname.[Name] = base.objectname
               AND dimobjectname.db_instance_id = diminstance.id
    WHERE base.projectHashId NOT IN
          (
              SELECT DISTINCT
                     hashid.projectHashId
              FROM [fact].UserBaseInfo base1
                  INNER JOIN dim.projecthashid hashid
                      ON hashid.id = base1.ProjectHashId
          )
    UNION
    SELECT LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, base.modify_date, 110)), 12) AS datetimeid,
           dimhasid.id,
           host.id,
           db.id,
           '10' AS CounterID,
           1 AS [CounterValue],
           dimusertype.id,
           dimuserdb.id,
           dimrole.id,
           dimpermtype.id,
           dimpermstate.id,
           dimobjectype.id,
           dimobjectname.id,
           dimport.id,
           dimrole.db_inst_id
    FROM stage.[USERUsersInfo] base
        INNER JOIN dim.projecthashid dimhasid
            ON dimhasid.projectHashId = base.projectHashId
        INNER JOIN dim.hostname host
            ON host.Hostname = base.fqdn
        INNER JOIN dim.databases db
            ON db.Hostname = host.id
               AND db.[Database] = base.databaseName
        INNER JOIN dim.usertype dimusertype
            ON dimusertype.UserType = base.usertype
        INNER JOIN dim.instance diminstance
            ON diminstance.name = base.servername
               AND diminstance.host_id = host.id
        INNER JOIN dim.databaseusername dimuserdb
            ON dimuserdb.DatabaseUserName = base.databaseusername
               AND dimuserdb.[host_id] = host.id
               AND dimuserdb.[instance_id] = diminstance.id
        INNER JOIN dim.role dimrole
            ON dimrole.Role = base.role
               AND dimrole.[host_id] = host.id
               AND dimrole.[db_id] = db.id
               AND dimrole.db_inst_id = diminstance.id
        INNER JOIN dim.permissiontype dimpermtype
            ON dimpermtype.permissiontype = base.permissiontype
        INNER JOIN dim.permissionstate dimpermstate
            ON dimpermstate.PermissionState = base.permissionstate
        INNER JOIN dim.objecttype dimobjectype
            ON dimobjectype.Type = base.objecttype
        INNER JOIN dim.port dimport
            ON dimport.port = base.portListen
               AND dimport.[host_id] = host.id
        INNER JOIN dim.objectname dimobjectname
            ON db.id = dimobjectname.[db_id]
               AND host.id = dimobjectname.[host_id]
               AND dimobjectname.[Name] = base.objectname
               AND dimobjectname.db_instance_id = diminstance.id
    WHERE base.projectHashId NOT IN
          (
              SELECT DISTINCT
                     hashid.projectHashId
              FROM [fact].UserBaseInfo base1
                  INNER JOIN dim.projecthashid hashid
                      ON hashid.id = base1.ProjectHashId
          );


    PRINT 'DIM Produktlevel';



    INSERT INTO [dim].[productlevel]
    (
        [ProductLevel],
        [Created]
    )
    SELECT base.ProductLevel,
           MIN(datetimeid) AS datetimeid
    FROM stage.[INSTANCEServerProperties] base
    WHERE base.ProductLevel IS NOT NULL
          AND NOT EXISTS
    (
        SELECT base.ProductLevel
        FROM [dim].[productlevel]
        WHERE [ProductLevel] = base.[ProductLevel]
    )
    GROUP BY [base].[ProductLevel];

    PRINT 'PRODUKTLEVEL ENDE';

    PRINT 'DIM ProduktVersion';

    INSERT INTO [dim].[productversion]
    (
        [productversion],
        [Created]
    )
    SELECT base.ProductVersion,
           MIN(datetimeid) AS datetimeid
    FROM stage.[INSTANCEServerProperties] base
    WHERE base.ProductVersion IS NOT NULL
          AND NOT EXISTS
    (
        SELECT base.ProductVersion
        FROM [dim].[productversion]
        WHERE [ProductVersion] = base.[ProductVersion]
    )
    GROUP BY [base].[ProductVersion];

    PRINT 'DIM ProduktVersion Ende';

    PRINT 'DIM Pproductmajorversion Start';



    INSERT INTO [dim].[productmajorversion]
    (
        productmajorversion,
        [Created]
    )
    SELECT base.ProductMajorVersion,
           MIN(datetimeid) AS datetimeid
    FROM stage.[INSTANCEServerProperties] base
    WHERE base.ProductMajorVersion IS NOT NULL
          AND NOT EXISTS
    (
        SELECT ProductMajorVersion
        FROM [dim].[productmajorversion]
        WHERE [ProductMajorVersion] = base.[productmajorversion ]
    )
    GROUP BY [base].[ProductMajorVersion];

    PRINT 'productmajorversion ENDE';


    PRINT 'productminorversion Start';



    INSERT INTO [dim].[productminorversion]
    (
        productminorversion,
        [Created]
    )
    SELECT base.ProductMinorVersion,
           MIN(datetimeid) AS datetimeid
    FROM stage.[INSTANCEServerProperties] base
    WHERE base.ProductMinorVersion IS NOT NULL
          AND NOT EXISTS
    (
        SELECT ProductMinorVersion
        FROM [dim].[productminorversion]
        WHERE [ProductMinorVersion] = base.[ProductMinorVersion]
    )
    GROUP BY [base].[ProductMinorVersion];

    PRINT 'productminorversion ENDE';

    PRINT 'virtualmachinetype Start';



    INSERT INTO [dim].[virtualmachinetype]
    (
        virtualmachinetype,
        [Created]
    )
    SELECT base.VirtualMachineType,
           MIN(datetimeid) AS datetimeid
    FROM [stage].[INSTANCEHardwareInfo] base
    WHERE base.VirtualMachineType IS NOT NULL
          AND NOT EXISTS
    (
        SELECT VirtualMachineType
        FROM [dim].[virtualmachinetype]
        WHERE [VirtualMachineType] = base.[VirtualMachineType]
    )
    GROUP BY [base].[VirtualMachineType];

    PRINT 'virtualmachinetype ENDE';
    --productminorversion

    PRINT 'ServiceAccounts Start';
    INSERT INTO [dim].[serviceaccounts]
    (
        [Created],
        [service_Account],
        [host_id],
        [db_instance_id],
        [service_name]
    )
    SELECT MIN(datetimeid) AS datetimeid,
           [service_account],
           host.id AS host_id,
           ins.id instance_id,
           [servicename]
    FROM [stage].[INSTANCESQLServerServicesInfo] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.instance ins
            ON ins.name = base.ServerName
    WHERE base.service_account IS NOT NULL
          AND NOT EXISTS
    (
        SELECT base.service_account
        FROM [dim].[serviceaccounts]
        WHERE [service_account] = base.[service_account]
    )
    GROUP BY service_account,
             host.id,
             ins.id,
             [servicename]
    ORDER BY 1;


    PRINT 'ServiceAccounts Ende';



    PRINT '[productupdatelevel Start';



    INSERT INTO [dim].[productupdatelevel]
    (
        productupdatelevel,
        [Created]
    )
    SELECT base.ProductUpdateLevel,
           MIN(datetimeid) AS datetimeid
    FROM stage.[INSTANCEServerProperties] base
    WHERE base.[ProductUpdateLevel] IS NOT NULL
          AND NOT EXISTS
    (
        SELECT ProductMinorVersion
        FROM [dim].[productupdatelevel]
        WHERE [ProductUpdateLevel] = base.[ProductUpdateLevel]
    )
    GROUP BY [base].[ProductUpdateLevel];

    PRINT '[productupdatelevel ENDE';



    PRINT '[Edition Start]';



    INSERT INTO [dim].[edition]
    (
        Edition,
        [Created]
    )
    SELECT base.Edition,
           MIN(datetimeid) AS datetimeid
    FROM stage.[INSTANCEServerProperties] base
    WHERE base.[Edition] IS NOT NULL
          AND NOT EXISTS
    (
        SELECT Edition FROM [dim].[Edition] WHERE [Edition] = base.[Edition]
    )
    GROUP BY [base].[Edition];

    PRINT '[Edition ENDE]';


    PRINT 'SYSADMIN  START';

    INSERT INTO [dim].[databaseusername]
    (
        [DatabaseUserName],
        [host_id],
        [instance_id],
        [Created]
    )
    SELECT base.[Name],
           host.id AS servername,
           dimins.id,
           MIN(base.[datetimeid]) AS datetimeid
    FROM [stage].[USERSystemAdministratorInfo] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.instance dimins
            ON dimins.[name] = base.ServerName
    WHERE base.Name IS NOT NULL
          AND NOT EXISTS
    (
        SELECT *
        FROM [dim].[databaseusername]
        WHERE [DatabaseUserName] = base.[Name]
              AND Hostname = host.Hostname
              AND instance_id = dimins.id
    )
    GROUP BY base.[Name],
             [FQDN],
             host.id,
             dimins.[id];

    PRINT 'SYSADMIN ENDE';

    SELECT [projectHashId],
           COUNT([DatabaseName]) AS MengeDB,
           [FQDN],
           [ServerName]
    INTO #CountDBs
    FROM [stage].[INSTANCEDatabaseProperties]
    GROUP BY [projectHashId],
             [FQDN],
             [ServerName];


    --TRUNCATE TABLE [fact].[ServerProperties];

    INSERT INTO [fact].[ServerProperties]
    (
        [DateTimeId],
        [ProjectHashId],
        [HostId],
        [ProductLevelId],
        [ProductMajorVersionId],
        [ProductVersionID],
        [ProductUpdateLevelId],
        [Instance_id],
        [EditionId],
        [CounterID],
        [Value]
    )
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '11' AS counter_ID,
           pinstmem.[PhysicalMemoryMB] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCESystemMemory] pinstmem
            ON pinstmem.projectHashId = base.projectHashId
               AND pinstmem.ServerName = base.ServerName
               AND pinstmem.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
		WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '24' AS counter_ID,
           pinstmem.[AvailableMemoryMB] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCESystemMemory] pinstmem
            ON pinstmem.projectHashId = base.projectHashId
               AND pinstmem.ServerName = base.ServerName
               AND pinstmem.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '13' AS counter_ID,
           pinsthw.[LogicalCPUCount] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEHardwareInfo] pinsthw
            ON pinsthw.projectHashId = base.projectHashId
               AND pinsthw.ServerName = base.ServerName
               AND pinsthw.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '12' AS counter_ID,
           pinsthw.[scheduler_count] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEHardwareInfo] pinsthw
            ON pinsthw.projectHashId = base.projectHashId
               AND pinsthw.ServerName = base.ServerName
               AND pinsthw.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '14' AS counter_ID,
           pinsthw.[SQLServerUpTimehrs] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEHardwareInfo] pinsthw
            ON pinsthw.projectHashId = base.projectHashId
               AND pinsthw.ServerName = base.ServerName
               AND pinsthw.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '16' AS counter_ID,
           pinsthw.[CommittedTargetMemoryMB] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEHardwareInfo] pinsthw
            ON pinsthw.projectHashId = base.projectHashId
               AND pinsthw.ServerName = base.ServerName
               AND pinsthw.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '17' AS counter_ID,
           pinsthw.[CommittedMemoryMB] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEHardwareInfo] pinsthw
            ON pinsthw.projectHashId = base.projectHashId
               AND pinsthw.ServerName = base.ServerName
               AND pinsthw.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '19' AS counter_ID,
           pinsthw.[PhysicalCPUCount] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEHardwareInfo] pinsthw
            ON pinsthw.projectHashId = base.projectHashId
               AND pinsthw.ServerName = base.ServerName
               AND pinsthw.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '23' AS counter_ID,
           1 AS 'Value'
    --pinsthw.[PhysicalCPUCount] AS Value


    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEHardwareInfo] pinsthw
            ON pinsthw.projectHashId = base.projectHashId
               AND pinsthw.ServerName = base.ServerName
               AND pinsthw.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
    WHERE pinsthw.VirtualMachineType = 'HYPERVISOR'
	and base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, pinsthw.[SQLServerStartTime], 110)), 12) AS datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '15' AS counter_ID,
           1 AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEHardwareInfo] pinsthw
            ON pinsthw.projectHashId = base.projectHashId
               AND pinsthw.ServerName = base.ServerName
               AND pinsthw.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '20' AS counter_ID,
           pcountdb.MengeDB AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN #CountDBs pcountdb
            ON pcountdb.projectHashId = base.projectHashId
               AND pcountdb.ServerName = base.ServerName
               AND pcountdb.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
		
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '27' AS counter_ID,
           pinstme.[memory_utilization_percentage] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEProcessMemory] pinstme
            ON pinstme.projectHashId = base.projectHashId
               AND pinstme.ServerName = base.ServerName
               AND pinstme.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId
    UNION
    SELECT base.datetimeid,
           phash.id,
           host.id AS hostid,
           plevel.id AS plevelid,
           pmajor.id AS pmajorid,
           pminor.id AS pminorid,
           pProductUpdateLevel.id AS pProductUpdateLevelid,
           pinstance.id AS pinstanceid,
           pedition.id AS pedition,
           '25' AS counter_ID,
           pinstme.[SQLServerMemoryUsageMB] AS Value
    FROM stage.[INSTANCEServerProperties] base
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.productlevel plevel
            ON plevel.ProductLevel = base.ProductLevel
        INNER JOIN dim.productmajorVersion pmajor
            ON base.ProductMajorVersion = pmajor.ProductMajorVersion
        INNER JOIN dim.ProductVersion pminor
            ON base.ProductVersion = pminor.ProductVersion
        INNER JOIN dim.ProductUpdateLevel pProductUpdateLevel
            ON base.ProductUpdateLevel = pProductUpdateLevel.ProductUpdateLevel
        INNER JOIN dim.edition pedition
            ON base.Edition = pedition.Edition
        INNER JOIN dim.instance pinstance
            ON base.ServerName = pinstance.name
        INNER JOIN [stage].[INSTANCEProcessMemory] pinstme
            ON pinstme.projectHashId = base.projectHashId
               AND pinstme.ServerName = base.ServerName
               AND pinstme.FQDN = host.Hostname
        INNER JOIN dim.projecthashid phash
            ON phash.projectHashId = base.projectHashId

			WHERE base.projectHashId IN
		(
		SELECT projecthashid FROM [dim].[projecthashid]
			WHERE Created in(
								SELECT  
								 MAX([Created])
								FROM [dim].[projecthashid]) 
  )
  SELECT base.datetimeid,
	phash.id,
	host.id as hostid,
	plevel.id AS plevelid,
	pmajor.id AS pmajorid,
	pminor.id AS pminorid,
	pupdate.id AS pProductUpdateLevelid,
	pinstance.id AS pinstanceid,
	pedition.id AS pedition,
	'40' AS counter_ID,
	CASE
		WHEN cpuutil.SystemMemoryState = 'Available physical memory is high' THEN 1
		ELSE 0
	END AS Value
FROM stage.INSTANCEServerProperties base
	INNER JOIN dim.hostname host
        ON host.Hostname = base.FQDN
    INNER JOIN dim.productlevel plevel
        ON plevel.ProductLevel = base.ProductLevel
    INNER JOIN dim.productmajorVersion pmajor
        ON base.ProductMajorVersion = pmajor.ProductMajorVersion
    INNER JOIN dim.ProductVersion pminor
        ON base.ProductVersion = pminor.ProductVersion
    INNER JOIN dim.ProductUpdateLevel pupdate
        ON base.ProductUpdateLevel = pupdate.ProductUpdateLevel
    INNER JOIN dim.edition pedition
        ON base.Edition = pedition.Edition
    INNER JOIN dim.instance pinstance
        ON base.ServerName = pinstance.name
	INNER JOIN stage.INSTANCECPUUtilization cpuutil
		ON cpuutil.projectHashId = base.projectHashId
			AND cpuutil.ServerName = base.ServerName
			AND cpuutil.FQDN = host.Hostname
	INNER JOIN dim.projecthashid phash
		ON phash.projectHashId = base.projectHashId
		WHERE base.projectHashId IN (SELECT projectHashId FROM dim.projectHashId WHERE Created IN (SELECT MAX(Created) FROM dim.projecthashid))
UNION
SELECT base.datetimeid,
	phash.id,
	host.id as hostid,
	plevel.id AS plevelid,
	pmajor.id AS pmajorid,
	pminor.id AS pminorid,
	pupdate.id AS pProductUpdateLevelid,
	pinstance.id AS pinstanceid,
	pedition.id AS pedition,
	'34' AS counter_ID,
	cpuutil.SQLProcessUtilization5 as Value
FROM stage.INSTANCEServerProperties base
	INNER JOIN dim.hostname host
        ON host.Hostname = base.FQDN
    INNER JOIN dim.productlevel plevel
        ON plevel.ProductLevel = base.ProductLevel
    INNER JOIN dim.productmajorVersion pmajor
        ON base.ProductMajorVersion = pmajor.ProductMajorVersion
    INNER JOIN dim.ProductVersion pminor
        ON base.ProductVersion = pminor.ProductVersion
    INNER JOIN dim.ProductUpdateLevel pupdate
        ON base.ProductUpdateLevel = pupdate.ProductUpdateLevel
    INNER JOIN dim.edition pedition
        ON base.Edition = pedition.Edition
    INNER JOIN dim.instance pinstance
        ON base.ServerName = pinstance.name
	INNER JOIN stage.INSTANCECPUUtilization cpuutil
		ON cpuutil.projectHashId = base.projectHashId
			AND cpuutil.ServerName = base.ServerName
			AND cpuutil.FQDN = host.Hostname
	INNER JOIN dim.projecthashid phash
		ON phash.projectHashId = base.projectHashId
		WHERE base.projectHashId IN (SELECT projectHashId FROM dim.projectHashId WHERE Created IN (SELECT MAX(Created) FROM dim.projecthashid))
UNION
SELECT base.datetimeid,
	phash.id,
	host.id as hostid,
	plevel.id AS plevelid,
	pmajor.id AS pmajorid,
	pminor.id AS pminorid,
	pupdate.id AS pProductUpdateLevelid,
	pinstance.id AS pinstanceid,
	pedition.id AS pedition,
	'35' AS counter_ID,
	cpuutil.SQLProcessUtilization10 as Value
FROM stage.INSTANCEServerProperties base
	INNER JOIN dim.hostname host
        ON host.Hostname = base.FQDN
    INNER JOIN dim.productlevel plevel
        ON plevel.ProductLevel = base.ProductLevel
    INNER JOIN dim.productmajorVersion pmajor
        ON base.ProductMajorVersion = pmajor.ProductMajorVersion
    INNER JOIN dim.ProductVersion pminor
        ON base.ProductVersion = pminor.ProductVersion
    INNER JOIN dim.ProductUpdateLevel pupdate
        ON base.ProductUpdateLevel = pupdate.ProductUpdateLevel
    INNER JOIN dim.edition pedition
        ON base.Edition = pedition.Edition
    INNER JOIN dim.instance pinstance
        ON base.ServerName = pinstance.name
	INNER JOIN stage.INSTANCECPUUtilization cpuutil
		ON cpuutil.projectHashId = base.projectHashId
			AND cpuutil.ServerName = base.ServerName
			AND cpuutil.FQDN = host.Hostname
	INNER JOIN dim.projecthashid phash
		ON phash.projectHashId = base.projectHashId
		WHERE base.projectHashId IN (SELECT projectHashId FROM dim.projectHashId WHERE Created IN (SELECT MAX(Created) FROM dim.projecthashid))
UNION
SELECT base.datetimeid,
	phash.id,
	host.id as hostid,
	plevel.id AS plevelid,
	pmajor.id AS pmajorid,
	pminor.id AS pminorid,
	pupdate.id AS pProductUpdateLevelid,
	pinstance.id AS pinstanceid,
	pedition.id AS pedition,
	'36' AS counter_ID,
	cpuutil.SQLProcessUtilization15 as Value
FROM stage.INSTANCEServerProperties base
	INNER JOIN dim.hostname host
        ON host.Hostname = base.FQDN
    INNER JOIN dim.productlevel plevel
        ON plevel.ProductLevel = base.ProductLevel
    INNER JOIN dim.productmajorVersion pmajor
        ON base.ProductMajorVersion = pmajor.ProductMajorVersion
    INNER JOIN dim.ProductVersion pminor
        ON base.ProductVersion = pminor.ProductVersion
    INNER JOIN dim.ProductUpdateLevel pupdate
        ON base.ProductUpdateLevel = pupdate.ProductUpdateLevel
    INNER JOIN dim.edition pedition
        ON base.Edition = pedition.Edition
    INNER JOIN dim.instance pinstance
        ON base.ServerName = pinstance.name
	INNER JOIN stage.INSTANCECPUUtilization cpuutil
		ON cpuutil.projectHashId = base.projectHashId
			AND cpuutil.ServerName = base.ServerName
			AND cpuutil.FQDN = host.Hostname
	INNER JOIN dim.projecthashid phash
		ON phash.projectHashId = base.projectHashId
		WHERE base.projectHashId IN (SELECT projectHashId FROM dim.projectHashId WHERE Created IN (SELECT MAX(Created) FROM dim.projecthashid))
UNION
SELECT base.datetimeid,
	phash.id,
	host.id as hostid,
	plevel.id AS plevelid,
	pmajor.id AS pmajorid,
	pminor.id AS pminorid,
	pupdate.id AS pProductUpdateLevelid,
	pinstance.id AS pinstanceid,
	pedition.id AS pedition,
	'37' AS counter_ID,
	cpuutil.SQLProcessUtilization5 as Value
FROM stage.INSTANCEServerProperties base
	INNER JOIN dim.hostname host
        ON host.Hostname = base.FQDN
    INNER JOIN dim.productlevel plevel
        ON plevel.ProductLevel = base.ProductLevel
    INNER JOIN dim.productmajorVersion pmajor
        ON base.ProductMajorVersion = pmajor.ProductMajorVersion
    INNER JOIN dim.ProductVersion pminor
        ON base.ProductVersion = pminor.ProductVersion
    INNER JOIN dim.ProductUpdateLevel pupdate
        ON base.ProductUpdateLevel = pupdate.ProductUpdateLevel
    INNER JOIN dim.edition pedition
        ON base.Edition = pedition.Edition
    INNER JOIN dim.instance pinstance
        ON base.ServerName = pinstance.name
	INNER JOIN stage.INSTANCECPUUtilization cpuutil
		ON cpuutil.projectHashId = base.projectHashId
			AND cpuutil.ServerName = base.ServerName
			AND cpuutil.FQDN = host.Hostname
	INNER JOIN dim.projecthashid phash
		ON phash.projectHashId = base.projectHashId
		WHERE base.projectHashId IN (SELECT projectHashId FROM dim.projectHashId WHERE Created IN (SELECT MAX(Created) FROM dim.projecthashid))
UNION
SELECT base.datetimeid,
	phash.id,
	host.id as hostid,
	plevel.id AS plevelid,
	pmajor.id AS pmajorid,
	pminor.id AS pminorid,
	pupdate.id AS pProductUpdateLevelid,
	pinstance.id AS pinstanceid,
	pedition.id AS pedition,
	'38' AS counter_ID,
	cpuutil.MaxServerMemory as Value
FROM stage.INSTANCEServerProperties base
	INNER JOIN dim.hostname host
        ON host.Hostname = base.FQDN
    INNER JOIN dim.productlevel plevel
        ON plevel.ProductLevel = base.ProductLevel
    INNER JOIN dim.productmajorVersion pmajor
        ON base.ProductMajorVersion = pmajor.ProductMajorVersion
    INNER JOIN dim.ProductVersion pminor
        ON base.ProductVersion = pminor.ProductVersion
    INNER JOIN dim.ProductUpdateLevel pupdate
        ON base.ProductUpdateLevel = pupdate.ProductUpdateLevel
    INNER JOIN dim.edition pedition
        ON base.Edition = pedition.Edition
    INNER JOIN dim.instance pinstance
        ON base.ServerName = pinstance.name
	INNER JOIN stage.INSTANCECPUUtilization cpuutil
		ON cpuutil.projectHashId = base.projectHashId
			AND cpuutil.ServerName = base.ServerName
			AND cpuutil.FQDN = host.Hostname
	INNER JOIN dim.projecthashid phash
		ON phash.projectHashId = base.projectHashId
		WHERE base.projectHashId IN (SELECT projectHashId FROM dim.projectHashId WHERE Created IN (SELECT MAX(Created) FROM dim.projecthashid))
UNION
SELECT base.datetimeid,
	phash.id,
	host.id as hostid,
	plevel.id AS plevelid,
	pmajor.id AS pmajorid,
	pminor.id AS pminorid,
	pupdate.id AS pProductUpdateLevelid,
	pinstance.id AS pinstanceid,
	pedition.id AS pedition,
	'39' AS counter_ID,
	cpuutil.PageLifeExpectancy as Value
FROM stage.INSTANCEServerProperties base
	INNER JOIN dim.hostname host
        ON host.Hostname = base.FQDN
    INNER JOIN dim.productlevel plevel
        ON plevel.ProductLevel = base.ProductLevel
    INNER JOIN dim.productmajorVersion pmajor
        ON base.ProductMajorVersion = pmajor.ProductMajorVersion
    INNER JOIN dim.ProductVersion pminor
        ON base.ProductVersion = pminor.ProductVersion
    INNER JOIN dim.ProductUpdateLevel pupdate
        ON base.ProductUpdateLevel = pupdate.ProductUpdateLevel
    INNER JOIN dim.edition pedition
        ON base.Edition = pedition.Edition
    INNER JOIN dim.instance pinstance
        ON base.ServerName = pinstance.name
	INNER JOIN stage.INSTANCECPUUtilization cpuutil
		ON cpuutil.projectHashId = base.projectHashId
			AND cpuutil.ServerName = base.ServerName
			AND cpuutil.FQDN = host.Hostname
	INNER JOIN dim.projecthashid phash
		ON phash.projectHashId = base.projectHashId
		WHERE base.projectHashId IN (SELECT projectHashId FROM dim.projectHashId WHERE Created IN (SELECT MAX(Created) FROM dim.projecthashid))

		
    PRINT 'FaktenTab Userinfo Sysadmin Start / Create';


    INSERT INTO [fact].[UserBaseInfoSysadmin]
    (
        [DateTimeId],
        [ProjectHashId],
        [HostId],
        [CounterId],
        [CounterValue],
        [DatabaseUsernameId],
        [ServerNameId]
    )
    SELECT LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, create_date, 110)), 12) AS datetimeid,
           dimhasid.id,
           host.id,
           '29' AS CounterID,
           1 AS [CounterValue],
           dbuser.id,
           inst.id
    FROM [stage].[USERSystemAdministratorInfo] base
        INNER JOIN dim.projecthashid dimhasid
            ON dimhasid.projectHashId = base.projectHashId
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.databases db
            ON db.Hostname = host.id
        INNER JOIN dim.instance inst
            ON inst.name = base.ServerName
        INNER JOIN dim.databaseusername dbuser
            ON dbuser.DatabaseUserName = base.Name
               AND dbuser.host_id = host.id
               AND dbuser.instance_id = inst.id
    WHERE base.projectHashId NOT IN
          (
              SELECT DISTINCT
                     hashid.projectHashId
              FROM fact.[UserBaseInfoSysadmin] base1
                  INNER JOIN dim.projecthashid hashid
                      ON hashid.id = base1.projectHashId
          )
    GROUP BY LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, create_date, 110)), 12),
             dimhasid.id,
             host.id,
             dbuser.id,
             inst.name,
             inst.id
    UNION
    SELECT LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, base.modify_date, 110)), 12) AS datetimeid,
           dimhasid.id,
           host.id,
           '31' AS CounterID,
           1 AS [CounterValue],
           dbuser.id,
           inst.id
    FROM [stage].[USERSystemAdministratorInfo] base
        INNER JOIN dim.projecthashid dimhasid
            ON dimhasid.projectHashId = base.projectHashId
        INNER JOIN dim.hostname host
            ON host.Hostname = base.FQDN
        INNER JOIN dim.databases db
            ON db.Hostname = host.id
        INNER JOIN dim.instance inst
            ON inst.name = base.ServerName
        INNER JOIN dim.databaseusername dbuser
            ON dbuser.DatabaseUserName = base.Name
               AND dbuser.host_id = host.id
               AND dbuser.instance_id = inst.id
    WHERE base.modify_date > base.create_date
          AND base.projectHashId NOT IN
              (
                  SELECT DISTINCT
                         hashid.projectHashId
                  FROM fact.[UserBaseInfoSysadmin] base1
                      INNER JOIN dim.projecthashid hashid
                          ON hashid.id = base1.projectHashId
              )
    GROUP BY LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, modify_date, 110)), 12),
             dimhasid.id,
             host.id,
             dbuser.id,
             inst.name,
             inst.id;

	
	PRINT 'FaktenTab ObjectModification Start/Create'

	SELECT LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, base.create_date, 110)), 12) AS datetimeid,
		dimhashid.id AS ProjectHashId,
		host.id AS HostnameId,
		db.id AS DatabaseId,
		ins.id AS instance,
		'32' AS CounterId,
		1 AS CounterValue,
		dimobjecttype.id AS TypeDescriptionId,
		dimobjectname.id AS ObjectNameId,
		base.create_date,
		base.schema_id AS SchemaId
		INTO #OMTemp
	FROM [stage].[DATABASEObjectModificationInfo] base
		INNER JOIN dim.projecthashid dimhashid
			ON dimhashid.projectHashId = base.projectHashId
		INNER JOIN dim.hostname host
			ON host.Hostname = base.FQDN
		INNER JOIN dim.databases db
			ON db.Hostname = host.id
		INNER JOIN dim.instance ins ON 
		ins.name=base.ServerName
		INNER JOIN dim.objecttype dimobjecttype 
			ON dimobjecttype.Type = LOWER(base.type_desc)
		INNER JOIN dim.instance diminstance
        ON diminstance.name = base.servername
            AND diminstance.host_id = host.id
		INNER JOIN dim.objectname dimobjectname
            ON db.id = dimobjectname.[db_id]
               AND host.id = dimobjectname.[host_id]
               AND dimobjectname.[Name] = base.name
               AND dimobjectname.db_instance_id = diminstance.id
	GROUP BY LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, base.create_date, 110)), 12),
             dimhashid.id,
             host.id,
             db.id,
			 ins.id,
			 dimobjecttype.id,
			 dimobjectname.id,
			 base.create_date,
			 base.schema_id
UNION
SELECT LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, base.modify_date, 110)), 12) AS datetimeid,
		dimhashid.id AS ProjectHashId,
		host.id AS HostnameId,
		db.id AS DatabaseId,
		ins.id AS instance,
		'33' AS CounterId,
		1 AS CounterValue,
		dimobjecttype.id AS TypeDescriptionId,
		dimobjectname.id AS ObjectNameId,
		base.create_date,
		base.schema_id AS SchemaId
	FROM [stage].[DATABASEObjectModificationInfo] base
		INNER JOIN dim.projecthashid dimhashid
			ON dimhashid.projectHashId = base.projectHashId
		INNER JOIN dim.hostname host
			ON host.Hostname = base.FQDN
		INNER JOIN dim.databases db
			ON db.Hostname = host.id
		INNER JOIN dim.instance ins ON 
		ins.name=base.ServerName
		INNER JOIN dim.objecttype dimobjecttype
			ON dimobjecttype.Type = LOWER(base.type_desc)
		INNER JOIN dim.instance diminstance
        ON diminstance.name = base.servername
            AND diminstance.host_id = host.id
		INNER JOIN dim.objectname dimobjectname
            ON db.id = dimobjectname.[db_id]
               AND host.id = dimobjectname.[host_id]
               AND dimobjectname.[Name] = base.name
               AND dimobjectname.db_instance_id = diminstance.id
	GROUP BY LEFT([dbo].[fn_generate_bigint](CONVERT(DATETIME, base.modify_date, 110)), 12),
             dimhashid.id,
             host.id,
             db.id,
			 ins.id,
			 dimobjecttype.id,
			 dimobjectname.id,
			 base.create_date,
			 base.schema_id

INSERT INTO [fact].[ObjectModification]
	(
		[DatetimeId],
		[ProjectHashId],
		[HostnameId],
		[DatabaseId],
		[instance],
		[CounterId],
		[CounterValue],
		[TypeDescriptionId],
		[ObjectNameId],
		[Date],
		[SchemaId]
	)
SELECT base.*
FROM #OMTemp base
LEFT OUTER JOIN fact.ObjectModification om
ON om.ProjectHashId = base.ProjectHashId AND
	om.HostnameId = base.HostnameId AND
	om.DatabaseId = base.DatabaseId AND
	om.instance = base.instance AND
	om.TypeDescriptionId = base.TypeDescriptionId AND
	om.ObjectNameId = base.ObjectNameId AND
	om.SchemaId = base.SchemaId AND
	om.DatetimeId = base.datetimeid

DROP TABLE #OMTEMP;

	PRINT 'FaktenTab ObjectModification Finished'



    SET @EndZeit = GETDATE();

    INSERT INTO [dbo].[log]
    (
        [hashid],
        [StartTime],
        [EndTime]
    )
    SELECT CONVERT(VARCHAR(255), NEWID()),
           @Starzeit,
           @EndZeit;

		   SELECT 'Bearbeitung beendet'

END;


GO
