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
	OutputJoltage INT,
	PreviousOutputJoltage INT
)

-- Add the chain of adapters
INSERT INTO @AdapterChain
SELECT OutputJoltage, LAG(OutputJoltage, 1, 0) OVER (ORDER BY OutputJoltage) AS 'PreviousOutputJoltage'
FROM @Input
ORDER BY OutputJoltage

-- Add the built-in adapter, which is always 3 higher than the highest adapter
INSERT INTO @AdapterChain
SELECT MAX(OutputJoltage) + 3, MAX(OutputJoltage)
FROM @Input

;WITH JoltDifferences(JoltDifference, Occurences) AS (
	SELECT OutputJoltage - PreviousOutputJoltage, COUNT(*)
	FROM @AdapterChain
	GROUP BY OutputJoltage - PreviousOutputJoltage
)

SELECT EXP(SUM(LOG(Occurences))) AS 'OccurencesMultiplied'
FROM JoltDifferences
WHERE JoltDifference IN (1, 3)
