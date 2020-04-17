SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [helper].[sp_hist_stop]
AS
-- Drop tables and remove triggers
PRINT 'Clear everything here.'
GO
