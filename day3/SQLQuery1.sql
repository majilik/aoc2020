-- Create function
CREATE TYPE SlopeTable AS TABLE (
	RowNumber INT,
	MapRow NVARCHAR(MAX)
)
GO

CREATE FUNCTION udfSlopeTreeCount(
	@Slope AS SlopeTable READONLY,
	@Tree NVARCHAR(1),
	@RightSteps INT,
	@DownSteps INT
)
RETURNS TABLE
AS
RETURN
	SELECT COUNT(*) AS TreeCount
	FROM (
		SELECT 
			RowNumber,
			MapRow,
			((((ROW_NUMBER() OVER (ORDER BY RowNumber)) - 1) * @RightSteps) % (LEN(MapRow))) + 1 AS Position
		FROM @Slope
		WHERE @DownSteps = 1 OR RowNumber % (@DownSteps) = 1
	) SteppedRows
	WHERE CHARINDEX(@Tree, MapRow, Position) = Position -- Tree exists at position
	AND RowNumber > 1
GO

-- Input handling
DECLARE @Input AS TABLE (
	RowNumber INT IDENTITY,
	MapRow NVARCHAR(MAX)
)

INSERT INTO @Input (MapRow)
SELECT TRIM(b.MapRow)
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day3\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day3\bulk_format.xml'  
) AS b;

DECLARE @InputAsSlopeTable SlopeTable
INSERT INTO @InputAsSlopeTable (RowNumber, MapRow)
SELECT RowNumber, MapRow
FROM @Input

-- Queries
-- Part 1
SELECT *
FROM udfSlopeTreeCount(@InputAsSlopeTable, '#', 3, 1)

-- Part 2

;WITH Slopes AS (
	SELECT 1 AS 'R', 1 AS 'D'
	UNION
	SELECT 3 AS 'R', 1 AS 'D'
	UNION
	SELECT 5 AS 'R', 1 AS 'D'
	UNION
	SELECT 7 AS 'R', 1 AS 'D'
	UNION
	SELECT 1 AS 'R', 2 AS 'D'
)
SELECT EXP(SUM(LOG(result.TreeCount))) AS 'MultipliedTreeCount'
FROM Slopes s
CROSS APPLY udfSlopeTreeCount(@InputAsSlopeTable, '#', s.R, s.D) result

-- Cleanup
DROP FUNCTION udfSlopeTreeCount
DROP TYPE SlopeTable