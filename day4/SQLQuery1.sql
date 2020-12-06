-- Functions
CREATE FUNCTION udfGetNumeric(@Expression NVARCHAR(MAX))
RETURNS INT AS 
BEGIN 
	DECLARE @Numeric INT
	SELECT @Numeric = CAST(LEFT(@Expression, PATINDEX('%[0-9][^0-9]%', @Expression)) AS INT)
	RETURN @Numeric
END
GO

CREATE FUNCTION udfGetUnit(@Expression NVARCHAR(MAX))
RETURNS NVARCHAR(MAX) AS 
BEGIN 
	DECLARE @Unit NVARCHAR(MAX)
	SELECT @Unit = RIGHT(@Expression, LEN(@Expression) - PATINDEX('%[0-9][^0-9]%', @Expression))
	RETURN @Unit
END
GO

-- Input handling
DECLARE @Input AS TABLE (
	RowNumber INT IDENTITY,
	Passport NVARCHAR(MAX)
)

INSERT INTO @Input (Passport)
SELECT TRIM(REPLACE(REPLACE(b.Passport, CHAR(10), ' '), CHAR(13), ''))
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day4\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day4\bulk_format.xml'  
) AS b;

-- Sanitize data
DECLARE @PassportData AS TABLE (
	RowNumber INT,
	[byr] NVARCHAR(MAX),
	[iyr] NVARCHAR(MAX),
	[eyr] NVARCHAR(MAX),
	[hgt] NVARCHAR(MAX),
	[hcl] NVARCHAR(MAX),
	[ecl] NVARCHAR(MAX),
	[pid] NVARCHAR(MAX),
	[cid] NVARCHAR(MAX)
)

;WITH PassportData AS (
	SELECT i.RowNumber, LEFT(s.value, CHARINDEX(':', s.value) - 1) AS [Key], RIGHT(s.value, LEN(s.value) - CHARINDEX(':', s.value)) AS [Value]
	FROM @Input i
	CROSS APPLY string_split(Passport, ' ') s
)

INSERT INTO @PassportData (
	[RowNumber], 
	[byr],
	[iyr],
	[eyr],
	[hgt],
	[hcl],
	[ecl],
	[pid],
	[cid]
)
SELECT *
FROM PassportData x
PIVOT(
	MAX([Value])
	FOR [Key] IN (
		[byr],
		[iyr],
		[eyr],
		[hgt],
		[hcl],
		[ecl],
		[pid],
		[cid]
	)
) AS p

-- Queries
-- Part 1
SELECT COUNT(*)
FROM @PassportData
WHERE byr IS NOT NULL
AND iyr IS NOT NULL
AND eyr IS NOT NULL
AND hgt IS NOT NULL
AND hcl IS NOT NULL
AND ecl IS NOT NULL
AND pid IS NOT NULL

-- Part 2
;WITH RequiredFields AS (
	SELECT *
	FROM @PassportData
	WHERE byr IS NOT NULL
	AND iyr IS NOT NULL
	AND eyr IS NOT NULL
	AND hgt IS NOT NULL
	AND hcl IS NOT NULL
	AND ecl IS NOT NULL
	AND pid IS NOT NULL
)
	
SELECT COUNT(*)
FROM RequiredFields
WHERE byr BETWEEN 1920 AND 2002
AND iyr BETWEEN 2010 AND 2020
AND eyr BETWEEN 2020 AND 2030
AND (
	(dbo.udfGetUnit(hgt) = 'in' AND dbo.udfGetNumeric(hgt) BETWEEN 59 AND 76) 
	OR
	(dbo.udfGetUnit(hgt) = 'cm' AND dbo.udfGetNumeric(hgt) BETWEEN 150 AND 193) 
)
AND hcl LIKE '#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
AND ecl IN ('amb', 'blu', 'brn', 'gry', 'grn', 'hzl', 'oth')
AND pid LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'

DROP FUNCTION udfGetNumeric
DROP FUNCTION udfGetUnit