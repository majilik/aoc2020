-- Input handling
DECLARE @Input AS TABLE (
	LineNumber INT IDENTITY,
	OutputJoltage INT
)
INSERT INTO @Input(OutputJoltage)
SELECT b.OutputJoltage
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day10\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day10\bulk_format.xml'
) AS b;


-- Queries
-- Part 1
DECLARE @AdapterChain AS TABLE (
	OutputJoltage INT
)

-- Add the starting point
INSERT INTO @AdapterChain
SELECT 0
-- Add the chain of adapters
INSERT INTO @AdapterChain
SELECT OutputJoltage
FROM @Input
ORDER BY OutputJoltage
-- Add the built-in adapter, which is always 3 higher than the highest adapter
INSERT INTO @AdapterChain
SELECT MAX(OutputJoltage) + 3
FROM @Input

;WITH Adapters(OutputJoltage, PreviousOutputJoltage) AS (
	SELECT OutputJoltage, LAG(OutputJoltage, 1, 0) OVER (ORDER BY OutputJoltage)
	FROM @AdapterChain
), JoltageDifferences(Difference, Occurences) AS (
	SELECT OutputJoltage - PreviousOutputJoltage, COUNT(*)
	FROM Adapters
	GROUP BY OutputJoltage - PreviousOutputJoltage
)

SELECT EXP(SUM(LOG(Occurences))) AS 'OccurencesMultiplied'
FROM JoltageDifferences
WHERE Difference IN (1, 3)


-- Part 2

/*
Legend:
X = Arrangement possible
1 = In use
0 = Not used

For each arrangement the start and end adapters must always be in use.
Therefore, for an arrangement of 5 adapters, only 3 may be altered. For 4 adapters only 2, for 3 only 1.

1 2 3 | X
------|
0 0 0 | 0 -> Can not reach next adapter
0 0 1 | 1
0 1 0 | 1
0 1 1 | 1
1 0 0 | 1
1 0 1 | 1
1 1 0 | 1
1 1 1 | 1

Result: 7 possible arrangements for 3 consecutive 1 differences

1 2 | X
----|
0 0 | 1
0 1 | 1
1 0 | 1
1 1 | 1

Result: 4 possible arrangements for 2 consecutive 1 differences

1 | X
--|
0 | 1
1 | 1

Result: 2 possible arrangements for 1 consecutive 1 differences
*/

;WITH Adapters(OutputJoltage, Difference) AS (
	SELECT 
		OutputJoltage, 
		OutputJoltage - LAG(OutputJoltage, 1, 0) OVER (ORDER BY OutputJoltage)
	FROM @AdapterChain
), FindArrangementStarts(OutputJoltage, ArrangementStarted) AS (
	SELECT 
		OutputJoltage, 
		CASE WHEN Difference = 1 THEN 0 ELSE 1 END
	FROM Adapters
), ApplyArrangementIds(OutputJoltage, ArrangementId) AS (
	SELECT
		OutputJoltage, 
		SUM(ArrangementStarted) OVER (ORDER BY OutputJoltage)
	FROM FindArrangementStarts
), AdaptersInArrangement(ArrangementId, AdapterCount) AS (
	SELECT ArrangementId, COUNT(OutputJoltage)
	FROM ApplyArrangementIds
	GROUP BY ArrangementId
), GetPossibleArrangementCounts(ArrangementCount) AS (
	SELECT POWER(7, COUNT(ArrangementId))
	FROM AdaptersInArrangement
	WHERE AdapterCount = 5

	UNION ALL

	SELECT POWER(4, COUNT(ArrangementId))
	FROM AdaptersInArrangement
	WHERE AdapterCount = 4

	UNION ALL

	SELECT POWER(2, COUNT(ArrangementId))
	FROM AdaptersInArrangement
	WHERE AdapterCount = 3
)

SELECT EXP(SUM(LOG(ArrangementCount))) AS 'ArrangementCountTotal'
FROM GetPossibleArrangementCounts