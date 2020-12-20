-- Functions
CREATE TYPE udtProgram AS TABLE (
	LineNumber INT,
	Operation NVARCHAR(3),
	Argument INT
)
GO
CREATE FUNCTION udfRunProgram(
	@Program AS udtProgram READONLY,
	@LineNumberOverride AS INT,
	@OperationOverride AS NVARCHAR(3)
)
RETURNS @ReturnValue TABLE (
	RanUntilEnd BIT,
	Accumulator INT
)
AS BEGIN
	DECLARE @PC INT = 1
	DECLARE @Acc INT = 0
	DECLARE @Op NVARCHAR(3)
	DECLARE @Arg INT
	DECLARE @MaxPC INT
	SELECT @MaxPC = MAX(LineNumber)
	FROM @Program
	DECLARE @VisitedLines AS TABLE (
		LineNumber INT
	)

	WHILE (@PC <= @MaxPC)
	BEGIN
		SELECT @Op = Operation, @Arg = Argument
		FROM @Program
		WHERE LineNumber = @PC

		IF EXISTS(SELECT * FROM @VisitedLines WHERE LineNumber = @PC)
		BEGIN
			BREAK
		END

		INSERT INTO @VisitedLines
		VALUES (@PC)

		IF @PC = @LineNumberOverride
		BEGIN
			SET @Op = @OperationOverride
		END
	
		IF @Op = 'acc'
		BEGIN
			SET @Acc = @Acc + @Arg
		END
		ELSE IF @Op = 'jmp'
		BEGIN
			SET @PC = @PC + @Arg
			CONTINUE
		END
	
		SET @PC = @PC + 1	
	END
	
	INSERT INTO @ReturnValue(RanUntilEnd, Accumulator)
	VALUES (
		CASE WHEN @PC >= @MaxPC THEN 1 ELSE 0 END, 
		@Acc
	)

	RETURN
END
GO

-- Input handling
DECLARE @Input AS TABLE (
	LineNumber INT IDENTITY,
	Operation NVARCHAR(3),
	Argument INT
)

INSERT INTO @Input (Operation, Argument)
SELECT b.Operation, b.Argument
FROM OPENROWSET (
		BULK 'C:\Users\David\Documents\aoc\aoc2020\day8\input.txt',
		FORMATFILE = 'C:\Users\David\Documents\aoc\aoc2020\day8\bulk_format.xml'  
) AS b;

DECLARE @Program AS dbo.udtProgram
INSERT INTO @Program
SELECT *
FROM @Input

-- Queries
-- Part 1
SELECT *
FROM dbo.udfRunProgram(@Program, DEFAULT, DEFAULT)

-- Part 2
-- Brute force JMP to NOP
;WITH ProgramRuns AS (
	SELECT x.RanUntilEnd, x.Accumulator
	FROM @Program p
	CROSS APPLY dbo.udfRunProgram(@Program, p.LineNumber, 'nop') x
	WHERE Operation = 'jmp'

	UNION ALL

	-- Brute force NOP to JMP
	SELECT x.RanUntilEnd, x.Accumulator
	FROM @Program p
	CROSS APPLY dbo.udfRunProgram(@Program, p.LineNumber, 'jmp') x
	WHERE Operation = 'nop'
)

SELECT *
FROM ProgramRuns
WHERE RanUntilEnd = 1

-- Cleanup
DROP FUNCTION dbo.udfRunProgram
DROP TYPE dbo.udtProgram