-- Functions

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

-- Queries
-- Part 1
DECLARE @PC INT = 1
DECLARE @Acc INT = 0
DECLARE @Op NVARCHAR(3)
DECLARE @Arg INT
DECLARE @MaxPC INT
SELECT @MaxPC = MAX(LineNumber)
FROM @Input
DECLARE @VisitedLines AS TABLE (
	LineNumber INT
)

WHILE (@PC <= @MaxPC)
BEGIN
	SELECT @Op = Operation, @Arg = Argument
	FROM @Input
	WHERE LineNumber = @PC

	PRINT 'PC: ' + CAST(@PC AS NVARCHAR(MAX)) + ' | Acc: ' + CAST(@Acc AS NVARCHAR(MAX)) + ' | Op: ' + @Op + ' | Arg: ' +  CAST(@Arg AS NVARCHAR(MAX)) 

	IF EXISTS(SELECT * FROM @VisitedLines WHERE LineNumber = @PC)
	BEGIN
		PRINT 'Revisiting already visited line, breaking program.'
		BREAK
	END

	INSERT INTO @VisitedLines
	VALUES (@PC)
	
	IF @Op = 'nop'
	BEGIN
		PRINT 'Program nop: Acc = ' + CAST(@Acc AS NVARCHAR(MAX))
	END
	ELSE IF @Op = 'acc'
	BEGIN
		SET @Acc = @Acc + @Arg
		PRINT 'Program accumulation: Acc = ' + CAST(@Acc AS NVARCHAR(MAX))
	END
	ELSE IF @Op = 'jmp'
	BEGIN
		SET @PC = @PC + @Arg
		PRINT 'Program jump: PC = ' + CAST(@PC AS NVARCHAR(MAX))
		CONTINUE
	END
	
	SET @PC = @PC + 1	
END

PRINT 'Program ended, Acc = ' + CAST(@Acc AS NVARCHAR(MAX))