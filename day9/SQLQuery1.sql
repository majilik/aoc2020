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

SELECT Number
FROM @Input x
WHERE x.LineNumber NOT IN (
	SELECT LineNumber
	FROM HasSumInNBefore
)
AND x.LineNumber > @N