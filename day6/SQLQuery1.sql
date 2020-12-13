-- Functions
CREATE FUNCTION udfExplodeString(
	@String NVARCHAR(MAX)
)
RETURNS 
@ReturnTable TABLE (
	[Character] NVARCHAR(MAX)
)
AS BEGIN
	;WITH cte_rec(exploded, src) AS (
		SELECT CAST(NULL AS NVARCHAR(MAX)), @String
		UNION ALL
		SELECT LEFT(src, 1), RIGHT(src, LEN(src) - 1)
		FROM cte_rec
		WHERE LEN(src) > 0
	)

	INSERT INTO @ReturnTable
	SELECT exploded
	FROM cte_rec
	WHERE exploded IS NOT NULL
	OPTION (maxrecursion 32767)

	RETURN 
END
GO

-- Input handling
DECLARE @Input AS TABLE (
	RowNumber INT IDENTITY,
	GroupAnswers NVARCHAR(MAX)
)

INSERT INTO @Input (GroupAnswers)
SELECT b.GroupAnswers
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day6\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day6\bulk_format.xml'  
) AS b;

-- Sanitize data
DECLARE @GroupAnswers AS TABLE (
	GroupNumber INT,
	Answers NVARCHAR(MAX)
)

INSERT INTO @GroupAnswers(GroupNumber, Answers)
SELECT i.RowNumber AS GroupNumber, s.[value] AS Answers
FROM @Input i
CROSS APPLY string_split(GroupAnswers, CHAR(10)) s

-- Queries
-- Part 1
SELECT SUM(z.DistinctAnswers) AS 'SumOfCounts'
FROM (
	SELECT x.GroupNumber, COUNT(DISTINCT y.[Character]) AS DistinctAnswers
	FROM (
		SELECT GroupNumber, STRING_AGG(Answers, '') AS Answers
		FROM @GroupAnswers
		GROUP BY GroupNumber
	) x
	CROSS APPLY dbo.udfExplodeString(Answers) y
	GROUP BY GroupNumber
) z

-- Part 2
;WITH cte AS (
	SELECT x.GroupNumber, x.PersonNumber, y.[Character]
	FROM (
		SELECT GroupNumber, ROW_NUMBER() OVER (PARTITION BY GroupNumber ORDER BY Answers) AS PersonNumber, Answers
		FROM @GroupAnswers
	) x
	CROSS APPLY dbo.udfExplodeString(Answers) y
), PersonsInGroups(GroupNumber, PersonCount) AS (
	SELECT GroupNumber, COUNT(DISTINCT PersonNumber)
	FROM cte
	GROUP BY GroupNumber
)

SELECT COUNT(*) AS 'SumOfCounts'
FROM (
	SELECT a.GroupNumber, [Character]
	FROM cte a
	JOIN PersonsInGroups pg ON a.GroupNumber = pg.GroupNumber
	GROUP BY a.GroupNumber, [Character], pg.PersonCount
	HAVING COUNT([Character]) = pg.PersonCount
) x

-- Cleanup
DROP FUNCTION dbo.udfExplodeString