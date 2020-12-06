-- Create Functions
CREATE FUNCTION udfBinarySearch(
	@TakeUpper NVARCHAR(1),
	@TakeLower NVARCHAR(1),
	@High INT,
	@Low INT,
	@BSP NVARCHAR(7)
)
RETURNS INT
AS BEGIN
DECLARE @Value INT

;WITH BinarySearch(lo, hi, bsp) AS (
	SELECT @Low, @High, @BSP
	UNION ALL
	SELECT 
		CASE 
			WHEN LEFT(bsp, 1) = @TakeLower THEN lo
			WHEN LEFT(bsp, 1) = @TakeUpper THEN (hi + lo)/2 + 1
		END,
		CASE 
			WHEN LEFT(bsp, 1) = @TakeLower THEN (hi + lo)/2
			WHEN LEFT(bsp, 1) = @TakeUpper THEN hi
		END,
		RIGHT(bsp, LEN(bsp) - 1) -- Consume BSP part
	FROM BinarySearch
	WHERE LEN(bsp) > 0
)

SELECT @Value = lo
FROM BinarySearch
WHERE bsp = ''

RETURN @Value
END
GO

-- Input handling
DECLARE @Input AS TABLE (
	RowNumber INT IDENTITY,
	BoardingPass NVARCHAR(MAX)
)

INSERT INTO @Input (BoardingPass)
SELECT TRIM(b.BoardingPass)
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day5\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day5\bulk_format.xml'  
) AS b;

-- Sanitize data
DECLARE @BoardingPass AS TABLE (
	RowNumber INT,
	RowBSP NVARCHAR(7),
	ColumnBSP NVARCHAR(3)
)
INSERT INTO @BoardingPass (RowNumber, RowBSP, ColumnBSP)
SELECT RowNumber, LEFT(BoardingPass, 7), RIGHT(BoardingPass, 3)
FROM @Input


-- Queries
-- Part 1
SELECT MAX([Row] * 8 + [Column]) AS [SeatID]
FROM (
	SELECT 
		RowNumber,
		dbo.udfBinarySearch('B', 'F', 127, 0, x.RowBSP) AS [Row], 
		dbo.udfBinarySearch('R', 'L', 7, 0, x.ColumnBSP) AS [Column]
	FROM @BoardingPass x
) y

-- Cleanup
DROP FUNCTION udfBinarySearch