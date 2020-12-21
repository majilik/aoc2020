-- Input handling
DECLARE @Input AS TABLE (
	LineNumber INT IDENTITY,
	Number BIGINT
)
INSERT INTO @Input(Number)
SELECT b.Number
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day9\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day9\bulk_format.xml'  
) AS b;

DECLARE @N AS INT = 25
DECLARE @Number AS BIGINT

-- Queries
-- Part 1
;WITH HasSumInNBefore AS (
	SELECT DISTINCT a.LineNumber, a.Number
	FROM @Input a
	JOIN @Input b ON a.LineNumber != b.LineNumber
	JOIN @Input c ON c.LineNumber != b.LineNumber AND c.Number + b.Number = a.Number
	WHERE b.LineNumber BETWEEN a.LineNumber - @N AND a.LineNumber
	AND c.LineNumber BETWEEN a.LineNumber - @N AND a.LineNumber
	AND a.LineNumber > @N
)

SELECT @Number = Number
FROM @Input x
WHERE x.LineNumber NOT IN (
	SELECT LineNumber
	FROM HasSumInNBefore
)
AND x.LineNumber > @N

SELECT @Number AS 'Answer 1'

-- Part 2
DECLARE @CurrentStartLine INT = 1
DECLARE @EndLine INT

WHILE (1=1)
BEGIN
	;WITH RunningTotal AS (
		SELECT LineNumber, Number, SUM(Number) OVER (ORDER BY LineNumber) AS 'Total'
		FROM @Input
		WHERE LineNumber >= @CurrentStartLine
	)
	
	SELECT @EndLine = LineNumber
	FROM RunningTotal
	WHERE Total = @Number

	IF (@EndLine IS NOT NULL)
		BREAK
	ELSE
		SET @CurrentStartLine = @CurrentStartLine + 1
END

SELECT MIN(Number) + MAX(Number) AS 'Answer 2'
FROM @Input
WHERE LineNumber BETWEEN @CurrentStartLine AND @EndLine