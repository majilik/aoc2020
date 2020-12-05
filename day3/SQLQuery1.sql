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

-- Part 1
DECLARE @Tree NVARCHAR(1) = '#'
DECLARE @RightSteps INT = 3
DECLARE @DownSteps INT = 1

SELECT COUNT(*) AS TreeCount
FROM (
	SELECT 
		RowNumber,
		MapRow,
		((((ROW_NUMBER() OVER (ORDER BY RowNumber)) - 1) * @RightSteps) % (LEN(MapRow))) + 1 AS Position
	FROM @Input
	WHERE RowNumber % (@DownSteps) = 0
) SteppedRows
WHERE CHARINDEX(@Tree, MapRow, Position) = Position -- Tree exists at position
AND RowNumber > 1

