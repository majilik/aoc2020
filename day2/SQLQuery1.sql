-- Input handling
DECLARE @Input AS TABLE (
  MinOccurs INT, 
  MaxOccurs INT,
  Letter NVARCHAR(1),
  PasswordToCheck NVARCHAR(MAX)
)

INSERT INTO @Input (MinOccurs, MaxOccurs, Letter, PasswordToCheck)
SELECT b.MinOccurs, b.MaxOccurs, b.Letter, b.PasswordToCheck
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\day2\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\day2\bulk_format.xml'  
) AS b;

-- Part 1
SELECT COUNT(*) AS 'PasswordsInPolicy'
FROM (
	SELECT LEN(PasswordToCheck) - LEN(REPLACE(PasswordToCheck, Letter, '')) AS Occurs, 
		MinOccurs, 
		MaxOccurs
	FROM @Input
) HandledPasswords
WHERE Occurs >= MinOccurs 
AND Occurs <= MaxOccurs

-- Part 2
SELECT *, CHARINDEX(Letter, PasswordToCheck, MinOccurs), CHARINDEX(Letter, PasswordToCheck, MaxOccurs)
FROM @Input
WHERE CHARINDEX(Letter, PasswordToCheck, MinOccurs) = MinOccurs
AND CHARINDEX(Letter, PasswordToCheck, MaxOccurs) = MaxOccurs