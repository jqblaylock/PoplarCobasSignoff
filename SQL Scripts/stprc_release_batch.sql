USE [CobasDITest]
GO
/****** Object:  StoredProcedure [dbo].[stprc_release_batch]    Script Date: 1/16/2017 4:14:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[stprc_release_batch] @batchNumber varchar(20), @batchReleaseUser varchar(30)
AS
BEGIN

--Testing
/*
DECLARE @batchNumber varchar(20), @batchReleaseUser varchar(30)
SELECT @batchNumber = '20140201173001', @batchReleaseUser = 'srichmond'
--EXEC stprc_release_batch @batchNumber, @batchReleaseUser
*/

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET CONCAT_NULL_YIELDS_NULL OFF

DECLARE @BatchId int, @errorMessage varchar(1000), @errorCode varchar(4), @successMessage varchar(1000), @releaseStatus varchar(15), @prevReleaseUser varchar(30), @batchDateString varchar(20)

SELECT @BatchId = id, @releaseStatus = releaseStatus, @prevReleaseUser = batchReleaseUser, @batchDateString = batchDateString
FROM Batch
WHERE batchNumber = @batchNumber

IF @BatchId IS NULL
BEGIN
	SELECT @errorCode = 'E1',  @errorMessage = 'Update to Batch failed.  Batch ' + @batchDateString + ' was not found.'
	GOTO errorSection
END ELSE IF @releaseStatus IS NOT NULL
BEGIN
	SELECT @errorCode = 'E2',  @errorMessage = 'Update to Batch failed.  Batch ' + @batchDateString + ' (Id = ' + CAST(@BatchId AS varchar) + ') has already been reviewed and ' + @releaseStatus + ' by user ' + @prevReleaseUser + '.'
	GOTO errorSection
END


-- Get Batch Details to perform Summit Insert
DECLARE @batchDetails TABLE (
	batchNumber varchar(20),
	batchDateString varchar(30),
	batchRunUser varchar(30),
	accessionNumber varchar(20),
	code varchar(20),
	result varchar(50)
)

INSERT INTO @batchDetails
EXEC stprc_get_batch_details @batchNumber

-- Add HPV ALL Results
DECLARE @hpvAllResult varchar(15)
IF EXISTS(
	SELECT code
	FROM @batchDetails bd
	WHERE bd.code IN ('02HPV16','02HPV18','02HPVOHR')
)
BEGIN
	IF EXISTS(
		SELECT code
		FROM @batchDetails bd
		WHERE bd.code IN ('02HPV16','02HPV18','02HPVOHR')
			AND bd.result LIKE 'POS%'
	)
	BEGIN
		SET @hpvAllResult = 'POS'
	END ELSE IF EXISTS (
		SELECT code
		FROM @batchDetails bd
		WHERE bd.code IN ('02HPV16','02HPV18','02HPVOHR')
			AND (bd.result LIKE 'INV%' OR bd.result LIKE 'IND%')
	)
	BEGIN
		SET @hpvAllResult = 'INV'
	END

	INSERT INTO @batchDetails(batchNumber, batchDateString, batchRunUser, accessionNumber, code, result)
	SELECT TOP 1 bd.batchNumber, bd.batchDateString, bd.batchRunUser, bd.accessionNumber, '02HPVALL', @hpvAllResult
	FROM @batchDetails bd
	WHERE bd.code IN ('02HPV16','02HPV18','02HPVOHR')
END

-- Insert Results into Summit
DECLARE @barcode varchar(20), @testCode varchar(30), @result varchar(255), @mappedResult varchar(255)

DECLARE insertCursor CURSOR LOCAL
FOR
	SELECT accessionNumber, code, result
	FROM @batchDetails
OPEN insertCursor
	FETCH NEXT FROM insertCursor INTO @barcode, @testCode, @result
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN

		SELECT @mappedResult = dbo.fn_map_cobas_rslt_to_summit(@testCode, @result)

		--PRINT 'EXEC [SUMMITSQL].[Summit-ProdBeta].dbo.stprc_peak_ins_di_rslt_summit ' + CAST(@BatchId AS varchar) + ',''' +  @barcode + ''', ''' + @testCode + ''', ''' + @mappedResult + ''', ''' + @batchReleaseUser + ''''
		EXEC [SUMMITSQL].[Summit-ProdBeta].dbo.stprc_peak_ins_di_rslt_summit @BatchId, @barcode, @testCode, @mappedResult, @batchReleaseUser

		SELECT @mappedResult = NULL

	FETCH NEXT FROM insertCursor INTO @barcode, @testCode, @result
	END
CLOSE insertCursor
DEALLOCATE insertCursor


-- Mark Batch as Released
BEGIN TRANSACTION
BEGIN TRY
	UPDATE Batch
	SET batchReleaseUser = @batchReleaseUser, releaseDate = GETDATE(), releaseStatus = 'RELEASED'
	WHERE id = @BatchId
END TRY
BEGIN CATCH
	SELECT @errorCode = 'E3',  @errorMessage = 'Update to Batch failed for batch ' + @batchDateString + ' (Id = ' + CAST(@BatchId AS varchar) + ').  -  ' + ERROR_MESSAGE()
END CATCH
IF @@TRANCOUNT > 0 COMMIT
SELECT @successMessage = 'Batch ' + @batchDateString + ' (Id = ' + CAST(@BatchId AS varchar) + ') has been released by user ' + @batchReleaseUser + '.'


SELECT @successMessage AS message

RETURN

--ERROR SECTION
errorSection:

SELECT @errorCode + ':  ' + @errorMessage AS message

END