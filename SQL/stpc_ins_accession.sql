USE [CobasDI]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE stprc_ins_accession @batchNumber varchar(20), @accessionNumber varchar(20), @batchRunUser varchar(30)
AS
BEGIN

--Testing
/*
DECLARE @batchNumber varchar(20), @accessionNumber varchar(20), @batchRunUser varchar(30)
SELECT @batchNumber = 'WHC-16-107883', @accessionNumber = 'WHC-16-107883', @batchRunUser = 'srichmond'
*/

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE @BatchId int, @AccessionId int, @errorMessage varchar(max), @errorCode varchar(4)


-- Insert Batch
IF NOT EXISTS(SELECT id FROM Batch WHERE batchNumber = @batchNumber)
BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO Batch(batchNumber, batchRunUser)
			SELECT @batchNumber, @batchRunUser
		END TRY
		BEGIN CATCH
			SELECT @errorCode = 'E1',  @errorMessage = 'Insert into "Batch" failed for batch number ' + @batchNumber + ' on case ' + @accessionNumber + '.  -  ' + ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 ROLLBACK
			GOTO errorSection
		END CATCH
  		IF @@TRANCOUNT > 0 COMMIT
  		SELECT @BatchId = @@IDENTITY
END ELSE
	SELECT @BatchId = id FROM Batch WHERE batchNumber = @batchNumber
END

-- Insert Accession
IF NOT EXISTS(SELECT id FROM Accession WHERE batchNumber = @batchNumber AND accessionNumber = @accessionNumber)
BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO Accession(BatchId, accessionNumber)
			SELECT @BatchId, @accessionNumber
		END TRY
		BEGIN CATCH
			SELECT @errorCode = 'E1',  @errorMessage = 'Insert into "Accession" failed for accession number ' + @accessionNumber + ' in batch ' + @batchNumber + '.  -  ' + ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 ROLLBACK
			GOTO errorSection
		END CATCH
  		IF @@TRANCOUNT > 0 COMMIT
  		SELECT @AccessionId = @@IDENTITY
END ELSE
	SELECT @BatchId = id FROM Batch WHERE batchNumber = @batchNumber
END



RETURN

--ERROR SECTION
errorSection:

SELECT @errorCode + ':  ' + @errorMessage AS ERROR



END

