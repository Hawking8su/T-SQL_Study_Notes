--T-SQL Fundamentals
--Chapter 10 Programmable Objects 
-- Variables
DECLARE @i AS INT;
SET @i = 10;
SELECT @i AS i;
---- or
DECLARE @i AS INT = 10;
---- assign value to a scalar variable using queries.
USE TSQLV4;
DECLARE @empname AS NVARCHAR(31);
SET @empname = (SELECT firstname + N' ' + lastname
								FROM HR.Employees
								WHERE empid = 3);
SELECT @empname AS empname;
---- nonstandard SELECT statement
DECLARE @firstname AS NVARCHAR(10), @lastname AS NVARCHAR(20)
SElECT 
 @firstname = firstname,
 @lastname = lastname 
FROM HR.Employees
WHERE empid = 3;

---- assginment SELECT is not safe
DECLARE @empname AS NVARCHAR(31);

SELECT @empname = firstname + N' ' + lastname
FROM HR.Employees
WHERE mgrid = 2;

SELECT @empname AS empname
---- SET is safer

DECLARE @empname AS NVARCHAR(31);

SET @empname = (SELECT firstname + N' ' + lastname
								FROM HR.Employees
								WHERE mgrid = 2);

SELECT @empname AS empname

-- Batch
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1(col1 INT);
GO
---- the code below will return an error
ALTER TABLE dbo.T1 ADD col2 INT;
SELECT col1, col2 FROM dbo.T1;
GO

---- GO n Option 
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
GO
CREATE TABLE dbo.T1(col1 INT IDENTITY);
GO
INSERT INTO dbo.T1 DEFAULT VALUES;
GO 100

SELECT * FROM dbo.T1;

-- Flow Element 
---- IF...ELSE
---- checks whether today is the last day of the year (in other words,
---- whether today's year is different from tomorrow's year).
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
	PRINT 'Today is the last day of the year.';
ELSE
	PRINT 'Today is not the last day of the year.';
---- more than two cases: nested IF...ELSE or CASE 
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
	PRINT 'Today is the last day of the year.';
ELSE
	IF MONTH(SYSDATETIME()) <> MONTH(DATEADD(day, 1, SYSDATETIME()))
		PRINT 'Today is the last day of the month but not the last day of the year.';
	ELSE 
		PRINT 'Today is not the last day of the month.';
--- statement block
IF DAY(SYSDATETIME())= 1
BEGIN
	PRINT 'Today is the first day of month.';
	PRINT 'Starting first-of-month-day process';
END
ELSE
BEGIN
	PRINT 'Today is not the first day of month.';
	PRINT 'Starting non-first-of-month-day process';
END

---- WHILE Loop 
DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN 
	PRINT @i
	SET @i = @i + 1
END 

DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN 
	IF @i = 6 BREAK
	PRINT @i
	SET @i = @i + 1
END 

DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN 
	SET @i = @i + 1
	IF @i = 6 CONTINUE
	PRINT @i
END 
---- An Example of Using IF and WHILE
SET NOCOUNT ON;
IF OBJECT_ID('dbo.Numbers', 'U') IS NOT NULL DROP TABLE dbo.Numbers;
CREATE TABLE dbo.Numbers(n INT NOT NULL PRIMARY KEY);
GO

DECLARE @i AS INT =1;
WHILE @i <= 1000
BEGIN 
	INSERT INTO dbo.Numbers(n) VALUES(@i);
	SET @i = @i + 1;
END
GO
SELECT * FROM dbo.Numbers;


-- Temporary Tables
USE TSQLV4;
---- Local temporary tables
IF OBJECT_ID('tempdb.dbo.#MyOrderTotalsByYear') IS NOT NULL
	DROP TABLE tempdb.dbo.#MyOrderTotalsByYear;
GO

CREATE TABLE #MyOrderTotalsByYear
(
	orderyear INT NOT NULL PRIMARY KEY,
	qty				INT NOT NULL
);

INSERT INTO #MyOrderTotalsByYear(orderyear, qty)
	SELECT 
		YEAR(O.orderdate) AS orderyear,
		SUM(OD.qty) AS qty
	FROM Sales.Orders AS O
		JOIN Sales.OrderDetails AS OD
			ON OD.orderid = O.orderid
	GROUP BY YEAR(O.orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM dbo.#MyOrderTotalsByYear AS Cur
	LEFT OUTER JOIN dbo.#MyOrderTotalsByYear AS Prv
		ON Cur.orderyear = Prv.orderyear + 1;

-- Global temporary tables
CREATE TABLE dbo.##Globals
(
	id sysname NOT NULL PRIMARY KEY,
	val SQL_VARIANT NOT NULL
);

INSERT INTO dbo.##Globals(id, val) VALUES(N'i', CAST(10 AS INT));
SELECT * FROM dbo.##Globals;

-- Table variables 
DECLARE @MyOrderTotalsByYear TABLE
(
	orderyear INT NOT NULL PRIMARY KEY,
	qty       INT NOT NULL
);

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
	SELECT 
		YEAR(O.orderdate) AS orderyear,
		SUM(OD.qty) AS qty
	FROM Sales.Orders AS O
		JOIN Sales.OrderDetails AS OD
			ON OD.orderid = O.orderid
	GROUP BY YEAR(O.orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM @MyOrderTotalsByYear AS Cur
	LEFT OUTER JOIN @MyOrderTotalsByYear AS Prv
		ON Cur.orderyear = Prv.orderyear + 1;

-- Table types
IF TYPE_ID('dbo.OrderTotalsByYear') IS NOT NULL
	DROP TYPE dbo.OrderTotalsByYear;
GO

CREATE TYPE dbo.OrderTotalsByYear AS TABLE
(
	orderyear INT NOT NULL PRIMARY KEY,
	qty       INT NOT NULL
);

DECLARE @MyOrderTotalsByYear AS dbo.OrderTotalsByYear;

-- Dynamic SQL
-- The EXEC Command
DECLARE @sql AS VARCHAR(100);
SET @sql = 'PRINT ''This message was printed by a dynamic SQL batch.'';'
EXEC(@sql); 

-- Routines
-- User-Defined Functions
IF OBJECT_ID('dbo.GetAge') IS NOT NULL DROP FUNCTION dbo.GetAge;
GO

CREATE FUNCTION dbo.GetAge
( -- define input variables
	@birthdate AS DATE,
	@eventdate AS DATE
)
RETURNS INT -- define output type
AS 
BEGIN 
	RETURN -- the function must has a RETURN clause that returns a value.
		DATEDIFF(year, @birthdate, @eventdate);
END;
GO

SELECT 
	empid, firstname, lastname, birthdate,
	dbo.GetAge(birthdate, SYSDATETIME()) AS age
FROM HR.Employees;

-- Stored Procedures
IF OBJECT_ID('Sales.GetCustomerOrders', 'P') IS NOT NULL
	DROP PROC Sales.GetCustomerOrders;
GO

CREATE PROC Sales.GetCustomerOrders
	@custid AS INT,
	@fromdate AS DATETIME = '19000101',
	@todate AS DATETIME = '99991231',
	@numrows AS INT OUTPUT -- indicate OUTPUT
AS 
SELECT orderid, custid, empid, orderdate 
FROM Sales.Orders
WHERE custid = @custid 
	AND orderdate >= @fromdate
	AND orderdate < @todate;

SET @numrows = @@ROWCOUNT;
GO

DECLARE @rc AS INT;

EXEC Sales.GetCustomerOrders
	@custid = 1,
	@fromdate = '20150101',
	@todate = '20160101',
	@numrows = @rc OUTPUT; -- specify OUTPUT

SELECT @rc AS numrows;

-- Cursors
USE TSQLV4;
---- Use cursor to calculate the running total quantity for each customer and month from the Sales.CustOrders view.
DECLARE @Result Table(
	custid INT,
	ordermonth DATETIME,
	qty INT,
	runqty INT,
	PRIMARY KEY(custid, ordermonth)
);

DECLARE
	@custid AS INT,
	@prvcustid AS INT,
	@ordermonth DATETIME,
	@qty AS INT,
	@runqty AS INT;

--(1) Declare cursor based on a query
DECLARE C CURSOR FOR -- FAST_FORWARD??
	SELECT custid, ordermonth, qty 
	FROM Sales.CustOrders
	ORDER BY custid, ordermonth;
--(2) Open the cursor
OPEN C;
--(3) Fetch the first record values into variables
FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;
SELECT @custid, @ordermonth, @qty; -- print values
SELECT @prvcustid = @custid, @runqty = 0;
--(4) Until the end of the cursor, loop through the cursor records
WHILE @@FETCH_STATUS = 0
BEGIN 
	IF @custid <> @prvcustid
		SELECT @prvcustid = @custid, @runqty = 0;
	SET @runqty = @runqty + @qty;
	INSERT INTO @Result VALUES(@custid, @ordermonth, @qty, @runqty);
	FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;  
	-- FETCH NEXT essentially influnce the @@FETCH_STATUS => Looping index
END
--(5) Close the cursor
CLOSE C;
--(6) Deallocate the cursor
DEALLOCATE C;

SELECT custid, CONVERT(VARCHAR(7), ordermonth, 121) AS ordermonth, qty, runqty
FROM @Result
ORDER BY custid, ordermonth;

