SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE stprc_ins_accession @batchNumber varchar(20), @batchDateString varchar(30), @accessionNumber varchar(20), @batchRunUser varchar(30)
AS
BEGIN

--Testing
/*
DECLARE @batchNumber varchar(20), @batchDateString varchar(30), @accessionNumber varchar(20), @batchRunUser varchar(30)
SELECT @batchNumber = '123456789', @accessionNumber = 'WHC-16-107883', @batchRunUser = 'srichmond'
EXEC stprc_ins_accession '123456789', 'WHC-16-107883', 'srichmond'
*/

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE @BatchId int, @AccessionId int, @errorMessage varchar(1000), @errorCode varchar(4), @successMessage varchar(1000)

-- Insert Batch
IF NOT EXISTS(SELECT id FROM Batch WHERE batchNumber = @batchNumber)
BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO Batch(batchNumber, batchDateString, batchRunUser)
			SELECT @batchNumber, @batchDateString, @batchRunUser
		END TRY
		BEGIN CATCH
			SELECT @errorCode = 'E1',  @errorMessage = 'Insert into "Batch" failed for batch number ' + @batchDateString + ' on case ' + @accessionNumber + '.  -  ' + ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 ROLLBACK
			GOTO errorSection
		END CATCH
  		IF @@TRANCOUNT > 0 COMMIT
  		SELECT @BatchId = @@IDENTITY

		SELECT @successMessage = 'Added row to "Batch" for batch number ' + @batchDateString + ' (Id = ' + CAST(@BatchId AS varchar) + ').  '
END ELSE
BEGIN
	SELECT @BatchId = id FROM Batch WHERE batchNumber = @batchNumber
	SELECT @successMessage = 'Row already exists for batch ' + @batchDateString + ' (Id =  ' + CAST(@BatchId AS varchar) + ').  '
END

-- Insert Accession
IF NOT EXISTS(SELECT id FROM Accession WHERE BatchId = @BatchId AND accessionNumber = @accessionNumber)
BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO Accession(BatchId, accessionNumber)
			SELECT @BatchId, @accessionNumber
		END TRY
		BEGIN CATCH
			SELECT @errorCode = 'E1',  @errorMessage = 'Insert into "Accession" failed for accession number ' + @accessionNumber + ' in batch ' + @batchDateString + '.  -  ' + ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 ROLLBACK
			GOTO errorSection
		END CATCH
  		IF @@TRANCOUNT > 0 COMMIT
  		SELECT @AccessionId = @@IDENTITY
		SELECT @successMessage = @successMessage + 'Added row to "Accession" for accession number' + @accessionNumber + ' (Id = ' + CAST(@AccessionId AS varchar) + ').'
END ELSE
BEGIN
	SELECT @AccessionId = id FROM Accession WHERE BatchId = @BatchId AND accessionNumber = @accessionNumber
	SELECT @successMessage = @successMessage + 'Row already exists for accession ' + @accessionNumber + ' (Id = ' + CAST(@AccessionId AS varchar) + ').'
END

SELECT @successMessage AS message, @BatchId AS BatchId, @AccessionId AS AccessionId

RETURN

--ERROR SECTION
errorSection:

SELECT @errorCode + ':  ' + @errorMessage AS message, @BatchId AS BatchId, @AccessionId AS AccessionId

END


