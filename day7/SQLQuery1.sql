-- Functions
CREATE FUNCTION udfGetQuantity(@Expression NVARCHAR(MAX))
RETURNS INT AS 
BEGIN 
	DECLARE @Quantity INT
	SELECT @Quantity = CAST(LEFT(@Expression, PATINDEX('%[0-9][^0-9]%', @Expression)) AS INT)
	RETURN @Quantity
END
GO

CREATE FUNCTION udfGetBagColor(@Expression NVARCHAR(MAX))
RETURNS NVARCHAR(MAX) AS 
BEGIN 
	DECLARE @Color NVARCHAR(MAX)
	SELECT @Color = RIGHT(@Expression, LEN(@Expression) - PATINDEX('%[0-9][^0-9]%', @Expression))
	RETURN TRIM(LEFT(@Color, PATINDEX('%bag%', @Expression) - LEN('bag')))
END
GO

-- Input handling
DECLARE @Input AS TABLE (
	RowData NVARCHAR(MAX)
)

INSERT INTO @Input (RowData)
SELECT b.RowData
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day7\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day7\bulk_format.xml'  
) AS b;

DECLARE @Bags AS TABLE (
	[ID]	INT IDENTITY,
	[Color] NVARCHAR(MAX)
)

DECLARE @BagContents AS TABLE (
	[BagID]	INT,
	[Quantity] INT,
	[HoldingBagID] INT
)

DECLARE @ParseParts AS TABLE (
	[Bag] NVARCHAR(MAX),
	[Contents] NVARCHAR(MAX)
)
INSERT INTO @ParseParts
SELECT 
	TRIM(LEFT(RowData, PATINDEX('%bags contain%', RowData) - 1)) AS 'Bag', 
	TRIM(RIGHT(RowData, LEN(RowData) - LEN('bags contain') - PATINDEX('%bags contain%', RowData))) AS 'Contents'
FROM @Input

INSERT INTO @Bags([Color])
SELECT Bag AS [Color]
FROM @ParseParts

;WITH ParsedBags(Color, Quantity, ContentColor) AS (
	SELECT Bag, dbo.udfGetQuantity(ContentEntry), dbo.udfGetBagColor(ContentEntry)
	FROM (
		SELECT x.Bag, TRIM(y.value) AS 'ContentEntry'
		FROM @ParseParts x
		CROSS APPLY STRING_SPLIT(x.Contents, ',') y
		WHERE y.value <> 'no other bags.'
	) i
)

/*
[Bags]
[ID], [Color]
1, shiny aqua
2, dark white
3, muted blue
4, vibrant lavender
5, dotted silver
6, dim indigo
...

[BagContents]
[BagID], [Quantity], [HoldingBagID]
1, 1, 2
3, 1, 4
3, 4, 5
3, 2, 6
...
*/
INSERT INTO @BagContents(BagID, Quantity, HoldingBagID)
SELECT b1.ID, pb.Quantity, b2.ID
FROM ParsedBags pb
LEFT JOIN @Bags b1 ON pb.Color = b1.Color
LEFT JOIN @Bags b2 ON pb.ContentColor = b2.Color

-- Queries
-- Part 1
DECLARE @ShinyGoldBagID INT
SELECT @ShinyGoldBagID = ID
FROM @Bags b
WHERE b.Color = 'shiny gold'

-- Get all ancestors that can contain shiny gold bag, directly and indirectly
;WITH cte_rec(BagID) AS (
	SELECT BagID
	FROM @BagContents bc
	WHERE bc.HoldingBagID = @ShinyGoldBagID

	UNION ALL

	SELECT b.BagID
	FROM cte_rec a
	JOIN @BagContents b ON a.BagID = b.HoldingBagID
)
SELECT COUNT(DISTINCT BagID) AS 'BagCount'
FROM cte_rec

-- Cleanup
DROP FUNCTION dbo.udfGetQuantity
DROP FUNCTION dbo.udfGetBagColor