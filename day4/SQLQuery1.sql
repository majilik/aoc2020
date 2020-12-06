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