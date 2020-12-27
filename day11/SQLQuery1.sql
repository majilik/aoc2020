-- Functions
CREATE TYPE MapTable AS TABLE (
	Generation INT,
	RowNumber INT,
	MapRow NVARCHAR(MAX)
)
GO

CREATE FUNCTION udfGetRange(
	@RangeStart INT,
	@RangeStop INT
)
RETURNS TABLE
AS
RETURN
(
	WITH Generator(Number) AS (
		SELECT @RangeStart
		UNION ALL
		SELECT Number + 1
		FROM Generator
		WHERE Number < @RangeStop
	)

	SELECT Number
	FROM Generator
)
GO

CREATE FUNCTION udfGetCell(
	@Map dbo.MapTable READONLY,
	@Generation INT,
	@Column INT,
	@Row INT
)
RETURNS NVARCHAR(1)
AS 
BEGIN
	DECLARE @Value NVARCHAR(1)

	SELECT @Value = SUBSTRING(m.MapRow, @Column, 1)
	FROM @Map m
	WHERE @Row = m.RowNumber
	AND @Generation = m.Generation

	RETURN @Value
END
GO

CREATE FUNCTION udfGetAdjacentCells(
	@Map dbo.MapTable READONLY,
	@Generation INT,
	@Column INT,
	@Row INT
)
RETURNS TABLE
AS
RETURN
(
	WITH cte1(x) AS (
		SELECT -1
		UNION
		SELECT 0
		UNION
		SELECT 1
	), cte2(c, r) AS (
		SELECT a.x, b.x
		FROM cte1 a
		JOIN cte1 b ON 1 = 1
	)

	SELECT ISNULL(dbo.udfGetCell(@Map, @Generation, @Column + c, @Row + r), '') AS 'Cell'
	FROM cte2
	WHERE c <> 0 OR r <> 0
)
GO

CREATE FUNCTION udfGetNextState(
	@Map dbo.MapTable READONLY,
	@Generation INT,
	@Column INT,
	@Row INT
)
RETURNS NVARCHAR(1)
AS
BEGIN
	DECLARE @Floor NVARCHAR(1) = '.'
	DECLARE @EmptySeat NVARCHAR(1) = 'L'
	DECLARE @OccupiedSeat NVARCHAR(1) = '#'
	DECLARE @CurrState NVARCHAR(1)
	SELECT @CurrState = dbo.udfGetCell(@Map, @Generation, @Column, @Row)
	
	-- Floor (.) never changes; seats don't move, and nobody sits on the floor.
	IF (@CurrState = @Floor)
		RETURN @Floor

	-- If a seat is empty (L) and there are no occupied seats adjacent to it, the seat becomes occupied.
	IF (@CurrState = @EmptySeat AND NOT EXISTS(
			SELECT *
			FROM dbo.udfGetAdjacentCells(@Map, @Generation, @Column, @Row)
			WHERE Cell = @OccupiedSeat
		))
		RETURN @OccupiedSeat

	-- If a seat is occupied (#) and four or more seats adjacent to it are also occupied, the seat becomes empty.
	IF (@CurrState = @OccupiedSeat)
	BEGIN
		DECLARE @OccupiedSeatsCount INT
		SELECT @OccupiedSeatsCount = COUNT(*)
		FROM dbo.udfGetAdjacentCells(@Map, @Generation, @Column, @Row)
		WHERE Cell = @OccupiedSeat

		IF (@OccupiedSeatsCount >= 4)
			RETURN @EmptySeat
	END

	-- Otherwise, the seat's state does not change.
	RETURN @CurrState
END
GO

-- Input handling
DECLARE @Input AS TABLE (
	RowNumber INT IDENTITY,
	MapRow NVARCHAR(MAX)
)
INSERT INTO @Input(MapRow)
SELECT REPLACE(b.MapRow, CHAR(13), '')
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day11\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day11\bulk_format.xml'
) AS b;

-- Queries
-- Part 1
DECLARE @CurrGeneration INT = 0
DECLARE @ColumnCount INT
DECLARE @RowCount INT
DECLARE @Map AS dbo.MapTable

INSERT INTO @Map(Generation, RowNumber, MapRow)
SELECT @CurrGeneration, RowNumber, MapRow
FROM @Input

SELECT TOP 1 @ColumnCount = LEN(MapRow)
FROM @Input

SELECT @RowCount = MAX(RowNumber)
FROM @Input

DECLARE @Matrix AS TABLE (
	C INT,
	R INT
)

INSERT INTO @Matrix(C, R)
SELECT c.Number, r.Number
FROM udfGetRange(1, @ColumnCount) c
JOIN udfGetRange(1, @RowCount) r  ON 1 = 1

WHILE (1=1)
BEGIN
	INSERT INTO @Map(Generation, RowNumber, MapRow)
	SELECT 
			@CurrGeneration + 1,
			nextGeneration.RowNumber, 
			STRING_AGG(nextGeneration.Cell, '') AS 'MapRow'
	FROM (
		SELECT 
			R AS 'RowNumber',
			dbo.udfGetNextState(@Map, @CurrGeneration, C, R) AS 'Cell'
		FROM @Matrix
	) nextGeneration
	GROUP BY nextGeneration.RowNumber
	
	-- Increment the generation counter for next loop
	SET @CurrGeneration = @CurrGeneration + 1

	-- Check if current generation and previous generation are equal
	IF NOT EXISTS(
		(
			SELECT RowNumber, MapRow
			FROM @Map
			WHERE Generation = @CurrGeneration - 1

			EXCEPT

			SELECT RowNumber, MapRow
			FROM @Map
			WHERE Generation = @CurrGeneration
		)

		UNION ALL

		(
			SELECT RowNumber, MapRow
			FROM @Map
			WHERE Generation = @CurrGeneration

			EXCEPT

			SELECT RowNumber, MapRow
			FROM @Map
			WHERE Generation = @CurrGeneration - 1
		)
	)
		-- If equal, break the execution since state has stabilized
		BREAK
	
END

SELECT SUM(LEN(MapRow) - LEN(REPLACE(MapRow, '#', ''))) AS 'OccupiedSeatsInStableState'
FROM @Map
WHERE Generation = @CurrGeneration

-- Cleanup
DROP FUNCTION dbo.udfGetRange
DROP FUNCTION dbo.udfGetAdjacentCells
DROP FUNCTION dbo.udfGetNextState
DROP FUNCTION dbo.udfGetCell
DROP TYPE dbo.MapTable