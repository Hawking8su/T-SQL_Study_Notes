# T-SQL Fundamentals
## Chapter 10 Programmable Objects
This chapter covers **variables; batches; flow elements; cursors; temporary tables; routines such as user-defined functions, stored procedures, and triggers; and dynamic SQL.**


### Variables
Variables allow you to temporarily store data values for later use in the same length in which they were declared.

Use a DECLARE statement to declare one or more variables, and use a SET statement to assign a value to a single variable.
```SQL
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
```

The SET statement can operate only on one variable at a time, so if you need to assign values to multiple attributes, you need to use multiple SET statements.

SQL Server also supports a nonstandard assignment SELECT statement, which allows you to query data and assign multiple values obtained from the same row to multiple variables by using a single statement.
```SQL
---- nonstandard assignment SELECT statement
DECLARE @firstname AS NVARCHAR(10), @lastname AS NVARCHAR(20)
SElECT
 @firstname = firstname,
 @lastname = lastname
FROM HR.Employees
WHERE empid = 3;
```

Note that if the query has more than one qualifying row in the SELECT predicate, the code doesn't fail. When the assignment SELECT finishes, the values in the variables are those from the last row that SQL Server happens to access -- you have to no control to this order.
```SQL
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
```

### Batches
A batch is one or more T-SQL statements sent by a client application to SQL Server for execution as a single unit. The batch undergoes parsing (syntax checking), resolution (checking the existence of referenced objects and columns), permissions checking, and optimizatio as a unit.

| Transaction                              | Batch                                                             |
| :-----------------------------           | :---------------------------------------------------------        |
| atomic unit of work                      | a single unit for execution (can have multiple transactions)      |
| undergo partial activity before rollback | no acitivity if parsing fails                                     |

SQL Server utilities such as SQL Server Management Studio provide a client command called GO that signals the end of a batch. Note that the GO command is a client command not a T-SQL server command.

#### A Batch As a Unit of Parsing
A batch is a set of commands that are parsed and executed as a unit. In the event of a syntax error in the batch, the whole batch is not submitted to SQL Server for execution.

#### Batches and Variables
A variable is local to the batch in which it is defined.

#### Statements That Cannot Be Combined in the Same Batch   
  - CREATE DEFAULT
  - CREATE FUNCTION
  - CREATE PROCEDURE
  - CREATE RULE
  - CREATE SCHEMA
  - CREATE TRIGGER
  - CREATE VIEW

```SQL
IF OBJECT_ID('Sales.MyView', 'V') IS NOT NULL DROP VIEW Sales.MyView
GO -- returns error if Go is omitted

CREATE VIEW Sales.MyView
AS
SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY YEAR(orderdate)
GO
```

#### A Batch As a Unit of Resolution
Meaning that checking the existence of objects and columns happens in the batch level.
```SQL
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1(col1 INT);
GO
-- the code below will return an error
ALTER TABLE dbo.T1 ADD col2 INT;
SELECT col1, col2 FROM dbo.T1;
GO
```

One best practice you can follow to avoid such problems is to separate DDL and DML statements into different batches.

#### The Go n Option
The GO command is not really a T-SQL command; it's actually a command used by SQL Server's client tools to denote the end of the batch. This command supports an argument indicating how many times you want to execute the batch.
```SQL
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
GO
CREATE TABLE dbo.T1(col1 INT IDENTITY);
GO
INSERT INTO dbo.T1 DEFAULT VALUES;
GO 100

SELECT * FROM dbo.T1;
```

### Flow Elements
#### The IF...ELSE Flow Element
Keep in mind that T-SQL uses three-valued logic and that the ELSE block is activated when the predicate is either FALSE or UNKNOWN.
```SQL
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

```

#### The WHILE Flow Element
The WHILE Element enables you to execute code in a loop.
```SQL
DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN
	PRINT @i
	SET @i = @i + 1
END
```
NOTE:
- Use BREAK command to break out of the current loop.
- USE CONTINUE command to skip the rest of activity in the current iteration.

#### An Example of Using IF and WHILE

```SQL
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
```

### Cursors
- Set or Multiset: a query without ORDER BY
- Cursor: a query with ORDER BY
	- a nonrelational result with order guaranteed among rows.
	- allows you to process rows from a result set of a query one at a time and in a requested order.

Your default choice should be to use set-based queries:
	- Cursors pretty much go against the relational model, which is based on set theory.
	- The record-by-record manipulation done by the curor has overhead.
	- With cursors, you spend a lot of code on the physical aspects of the solution. With set-based solutions, you mainly focus on the logical aspects of the solution.

Working with cursors is like fishing with a rod and catching one fish at a time. Working with sets, on the other hand, is like fishing with a net and catching a whole group of fish at one time.

Exceptions to consider cursors:
- you need to apply certain task to each row from some table or view.
- when your set-based solutions performs badly and you exhaust your tuning efforts using the set-based approach. Those cases tend to be calculations that, if done by processing one row at a time in a certain order.

Working with a cursor generally involves the following steps:
1. Declare the cursor based on a query.
2. Open the cursor
3. Fetch attribute values from the first cursor record into variables.
4. Until the end of the cursor is reached, loop through the cursor records; in each iteration of the loop, fetch attribute values from the current record into variables and perform the processing needed for the current row. Note that until the cursor reachs the end, the value of a function called @@FETCH_STATUS is 0.
5. Close the cursor
6. Deallocate the cursor

Example: use cursor to calculate the running total quantity for each customer and month from the Sales.CustOrders view.
```SQL
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

```


### Temporary Tables
Suppose you need the data to be visible only to the current session, or even only to the current batch, you can use Temporary tables.

Three kinds of temporary tables:
- local temporary tables
- global temporary tables
- table variables

#### Local Temporary Tables
A local temporary table is visible only to the session that created it, in the creating level and all inner levels in the call stack.

Typical scenarios of using local temporary tables:
- needs to store intermediate results and later query the data.
- need to access the result of some expensive processing multiple times
```SQL
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
-- it's generally recommended that you clean up the resources as soon as
-- you are done working with them.
IF OBJECT_ID('tempdb.dbo.#MyOrderTotalsByYear') IS NOT NULL
	DROP TABLE tempdb.dbo.#MyOrderTotalsByYear;
GO
```
#### Global Temporary tables
Global temporary tables is visible to all other sessions. They are destroied automatically when the creating session disconnects and there are no active reference to the table.
```SQL
CREATE TABLE dbo.##Globals
(
	id sysname NOT NULL PRIMARY KEY,
	val SQL_VARIANT NOT NULL
);

INSERT INTO dbo.##Globals(id, val) VALUES(N'i', CAST(10 AS INT));
SELECT * FROM dbo.##Globals;
```

#### Table Variables

| aspects            | Temporary tables                 | Table variables                           |
| :-------------     | :-------------                   | :-------------                            |
| presence           | tempdb--creating session         | tempdb--creating session--current batch   |
| case of roll back  | roll back as well                | not roll back                             |
| optimization       | for very small volumn of data   | relatively large volumn of data            |

```SQL
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
```

#### Table Types
When you create a table type, you preserve a table definition in the database and can later reuse it as the table definition of table variables and input parameters of stored procedures and user-defined functions.

After the table type is created, whenever you need to declare a table variable based on the table type's definition, you won't need to repeat the code.
```SQL

IF TYPE_ID('dbo.OrderTotalsByYear') IS NOT NULL
	DROP TYPE dbo.OrderTotalsByYear;
GO

CREATE TYPE dbo.OrderTotalsByYear AS TABLE
(
	orderyear INT NOT NULL PRIMARY KEY,
	qty       INT NOT NULL
);

DECLARE @MyOrderTotalsByYear AS dbo.OrderTotalsByYear;

```

### Dynamic SQL
SQL Server allows you to construct a batch of T-SQL code as *a character string* and then execute that batch.

Dynamic SQL is used for several purposes:
- Automating administrative tasks
- Improving performance of certain tasks
- Constructing elements of the code based on querying the actual data.

**SQL injection**: be extremely careful when concatenating user input as part of your code.

Two ways of executing dynamic SQL:
- using the EXEC command
- using the sp_executesql stored procedure

#### The EXEC command
```SQL
DECLARE @sql AS VARCHAR(100);
SET @sql = 'PRINT ''This message was printed by a dynamic SQL batch.'';'
EXEC(@sql);
```

#### The sp_executesql Stored procedure
See book P360.

#### Using PIVOT with Dynamic SQL
See book P361.

### Routines
Routines are programmable objects that encapsulate code to calculate a result or to execute activity. SQL Server supports 3 types of routines:
- user-defined functions
- stored procedures
- triggers

#### User-Defined Functions
The purpose of a UDF is to encapsulate logic that calculates something and return a result. SQL Server supports three types of UDFs: scalar, aggregate, and table-valued UDFs.

Key points:
- One benefit of using UDFs is that you can incorporate them in queries.
- UDFs are not allowed to have any side effects.
- UDFs must has a RETURN clause that returns a value.
```SQL
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

```

#### Stored Procedures
Store procedures are server-side routines that encapsulate T-SQL code. Compared to using ad-hoc code, the use of stored procedures gives you many benefits:
- encapsulate logic.
- give you better control of security.
- you can incorporate all error handling code within a procedure, silently taking corrective action where relevant.
- stored procedures give you performance benefits.
```SQL
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
```
#### Triggers
A trigger is a special kind of stored procedure -- one that cannot be executed explicitly. Instead, it is attached to an event. SQL Server supports the association of triggers with 2 kinds of events:
	- Data manipulation events (DML triggers), i.e. INSERT
	- Data definition events (DDL triggers), i.e. CREATE TABLE.

A trigger is considered part of the transaction that includes the event that caused the trigger to fire. Issuing a ROLLBACK TRAN command within the trigger's code causes a rollback of all changes that took place in the trigger, and also of all changes that took place in the transaction associated with the trigger.

Triggers in SQL Server fires per statement not per modified row.

##### DML Triggers
SQL Server supports 2 kinds of DML triggers:
	- *after:* fires after the event it is associated with finishes and can only be defined on permanent tables.
	- *instead of:* fires instead of the event it associated with and can be defined on permanent tables and views.
```SQL

CREATE TABLE dbo.T1
(
	keycol  INT         NOT NULL PRIMARY KEY,
	datacol VARCHAR(10) NOT NULL
)

CREATE TABLE dbo.T1_Audit
(
	audit_lsn  INT         NOT NULL IDENTITY PRIMARY KEY,
	dt         DATETIME    NOT NULL DEFAULT(SYSDATETIME()),
	login_name sysname     NOT NULL DEFAULT(ORIGINAL_LOGIN()),
	keycol     INT         NOT NULL,
	datacol    VARCHAR(10) NOT NULL
)
---- create DML trigger
CREATE TRIGGER trg_T1_insert_audit ON dbo.T1 AFTER INSERT
AS
INSERT INTO dbo.T1_Audit(keycol, datacol)
	SELECT keycol, datacol FROM inserted;
GO
---- fires the trigger
INSERT INTO dbo.T1(keycol, datacol) VALUES(10, 'a');
INSERT INTO dbo.T1(keycol, datacol) VALUES(30, 'x');
INSERT INTO dbo.T1(keycol, datacol) VALUES(20, 'g');
SELECT * FROM dbo.T1_Audit;
```

##### DDL Triggers
SQL Server supports the creation of DDL triggers at 2 scope:
	- events at database scope: CREATE TABLE.
	- events at server scope: CREATE DATABASE.

SQL Server DDL triggers only support *after* (does not support *instead of*).

*EVENTDATA* function: returns trigger event information as an XML value. You can use XQuery expressions to extract event attributes.

```SQL

CREATE TABLE dbo.AuditDDLEvents
(
	audit_lsn INT NOT NULL IDENTITY,
	posttime DATETIME NOT NULL,
	eventtype sysname NOT NULL,
	loginname sysname NOT NULL,
	schemaname sysname NOT NULL,
	objectname sysname NOT NULL,
	targetobjectname sysname NULL,
	eventdata XML NOT NULL,
	CONSTRAINT PK_AuditDDLEvents PRIMARY KEY(audit_lsn)
)

---- create DDL Triggers
CREATE TRIGGER trg_audit_ddl_events
ON DATABASE FOR DDL_DATABASE_LEVEL_EVENTS
AS
SET NOCOUNT ON;
DECLARE @eventdata AS XML = eventdata();
INSERT INTO dbo.AuditDDLEvents(
	posttime, eventtype, loginname, schemaname,
	objectname, targetobjectname, eventdata)
VALUES(
	@eventdata.value('(/EVENT_INSTANCE/PostTime)[1]', 'VARCHAR(23)'),
	@eventdata.value('(/EVENT_INSTANCE/EventType)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/LoginName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/TargetObjectName)[1]', 'sysname'),
	@eventdata);
GO

CREATE TABLE dbo.T1(col1 INT NOT NULL PRIMARY KEY);
ALTER TABLE dbo.T1 ADD col2 INT NULL;
ALTER TABLE dbo.T1 ALTER COLUMN col2 INT NOT NULL;
CREATE NONCLUSTERED INDEX idx1 ON dbo.T1(col2);
GO
SELECT * FROM dbo.AuditDDLEvents;

```

### Error Handling
The main tool used for error handling is a construct called TRY...CATCH.
```SQL
BEGIN TRY
	PRINT 10/0;
	PRINT 'No error';
END TRY
BEGIN CATCH
	PRINT 'Error';
END CATCH;
```
Note that if a TRY...CATCH block captures and handles an error, as far as the caller is concerned, there was no error.

Typically, error handling involves some work in the CATCH block investigating the cause of the error and taking a course of action. Useful error functions include:
	- ERROR_NUMBER() & ERROR_MESSAGE()
	- ERROR_SERVERITY() & ERROR_STATE()
	- ERROR_LINE(): return the line number where the error happened.
	- ERROR_PROCEDURE(): return the name of the procedure in which the error happened.

```SQL
-- show all warning messages in the system.
SELECT * FROM sys.messages;
```

Note that you can re-throw an error by using THROW command in the CATCH block.

A more detailed example:
```SQL
IF OBJECT_ID('dbo.Employees') IS NOT NULL DROP TABLE dbo.Employees;
GO

CREATE TABLE dbo.Employees
(
	 empid INT NOT NULL,
	 empname VARCHAR(25) NOT NULL,
	 mgrid INT NULL,
	 CONSTRAINT PK_Employees PRIMARY KEY(empid),
	 CONSTRAINT CHK_Employees_empid CHECK(empid > 0),
	 CONSTRAINT FK_Employees_Employees
	 FOREIGN KEY(mgrid) REFERENCES dbo.Employees(empid)
);
BEGIN TRY
	INSERT INTO dbo.Employees(empid, empname, mgrid)
		VALUES(1, 'Emp1', NULL);
END TRY
BEGIN CATCH
	IF ERROR_NUMBER() = 2627
	BEGIN
		PRINT '  Handling PK violation...';
	END
	ELSE IF ERROR_NUMBER() = 547
	BEGIN
		PRINT '  Handling CHECK/FK constraint violation...';
	END
	ELSE IF ERROR_NUMBER() = 514
	BEGIN
		PRINT '  Handling NULL violation...';
	END
	ELSE IF ERROR_NUMBER() = 245
	BEGIN
		PRINT '  Handling conversion error...';
	END
	ELSE
	BEGIN
		PRINT 'Re-throwing error...';
		THROW; -- throw error.
	END
END CATCH

-- Note that you can create a stored procedure that encapsulates resusable error-handling code
IF OBJECT_ID('dbo.ErrInsertHandler', 'P') IS NOT NULL DROP PROC dbo.ErrInsertHandler;
GO

CREATE PROC dbo.ErrInsertHandler
AS
SET NOCOUNT ON;

IF ERROR_NUMBER() = 2627
BEGIN
	PRINT '  Handling PK violation...';
END
ELSE IF ERROR_NUMBER() = 547
BEGIN
	PRINT '  Handling CHECK/FK constraint violation...';
END
ELSE IF ERROR_NUMBER() = 514
BEGIN
	PRINT '  Handling NULL violation...';
END
ELSE IF ERROR_NUMBER() = 245
BEGIN
	PRINT '  Handling conversion error...';
END
GO

-- You can execute the error handling procedure in the CATCH block.
BEGIN TRY
	INSERT INTO dbo.Employees(empid, empname, mgrid)
		VALUES(1, 'Emp1', NULL);
END TRY
BEGIN CATCH
	IF ERROR_NUMBER() IN (2627, 547, 515, 245)
		EXEC dbo.ErrInsertHandler;
	ELSE
		THROW;
END CATCH;

```
