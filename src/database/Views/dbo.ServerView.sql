SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[ServerView]
AS
SELECT        TOP (100) PERCENT MIN(datet.DayMonthYearAsText) AS Last_ScanDate, COUNT(datet.DayMonthYearAsText) AS MengeScans, host.Hostname, plevel.ProductLevel, pmj.ProductMajorVersion, pule.productversion, 
                         pins.name AS InstanceName, pedi.Edition
FROM            fact.ServerProperties AS fact INNER JOIN
                         dim.hostname AS host ON host.id = fact.HostId INNER JOIN
                         dim.productlevel AS plevel ON plevel.id = fact.ProductLevelId INNER JOIN
                         dim.productmajorversion AS pmj ON pmj.id = fact.ProductMajorVersionId INNER JOIN
                         dim.productlevel AS pmi ON pmi.id = fact.ProductLevelId INNER JOIN
                         dim.productversion AS pule ON pule.id = fact.ProductVersionID INNER JOIN
                         dim.instance AS pins ON pins.id = fact.Instance_id INNER JOIN
                         dim.edition AS pedi ON pedi.id = fact.EditionId INNER JOIN
                         dim.DateTime AS datet ON datet.DateTimeID = fact.DateTimeId INNER JOIN
                         dim.projecthashid AS pro ON pro.id = fact.ProjectHashId
GROUP BY host.Hostname, plevel.ProductLevel, pmj.ProductMajorVersion, pmi.ProductLevel, pule.productversion, pins.name, pedi.Edition
ORDER BY 1
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "fact"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 265
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "host"
            Begin Extent = 
               Top = 6
               Left = 303
               Bottom = 119
               Right = 489
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "plevel"
            Begin Extent = 
               Top = 6
               Left = 527
               Bottom = 119
               Right = 713
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pmj"
            Begin Extent = 
               Top = 6
               Left = 751
               Bottom = 119
               Right = 968
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pmi"
            Begin Extent = 
               Top = 6
               Left = 1006
               Bottom = 119
               Right = 1192
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pule"
            Begin Extent = 
               Top = 120
               Left = 303
               Bottom = 233
               Right = 489
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pins"
            Begin Extent = 
               Top = 120
               Left = 527
               Bottom = 250
               Right = 713
            End
            DisplayFlags = 280
            TopColumn ', 'SCHEMA', N'dbo', 'VIEW', N'ServerView', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'= 0
         End
         Begin Table = "pedi"
            Begin Extent = 
               Top = 120
               Left = 751
               Bottom = 233
               Right = 937
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "datet"
            Begin Extent = 
               Top = 120
               Left = 975
               Bottom = 250
               Right = 1204
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pro"
            Begin Extent = 
               Top = 6
               Left = 1230
               Bottom = 119
               Right = 1416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'ServerView', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'ServerView', NULL, NULL
GO
