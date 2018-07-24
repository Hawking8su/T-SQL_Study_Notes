-- T-SQL Fundamentals
-- Chapter 2 Single-Table Queries
USE TSQLV4;

SELECT * FROM Sales.Orders;
SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS numbers
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1
ORDER BY empid, orderyear;

-- GROUP BY
SELECT 
	empid, 
	YEAR(orderdate) AS orderyear,
	SUM(freight) AS totalfreight,
	COUNT(*) AS numorders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);

-- HAVING 
SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*)
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1;

-- TOP 
SELECT TOP(1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

SELECT TOP(5) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- OFFSET-FETCH
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate, orderid
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;

-- Window Functions: ROW_NUMBER() 
SELECT orderid, custid, val,
	ROW_NUMBER() OVER(PARTITION BY custid
					  ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;

-- IN
SELECT a.orderid, a.empid, a.orderdate
FROM Sales.Orders a
WHERE a.orderid IN (10248, 10249, 10250);

-- BETWEEN... AND...
SELECT a.orderid, a.empid, a.orderdate
FROM Sales.Orders a
WHERE a.orderid BETWEEN 10300 AND 10310;

-- LIKE 
SELECT a.empid, a.firstname, a.lastname
FROM HR.Employees a
WHERE lastname LIKE N'D%';

-- Readability with Parentheses
SELECT a.orderid, a.custid, a.empid, a.orderdate
FROM Sales.Orders a
WHERE 
	(custid = 1 AND empid IN (1, 3, 5))
  OR(custid = 85 AND empid IN (2, 4, 6));

-- CASE
---- simple CASE form
SELECT a.productid, a.productname, a.categoryid,
  CASE a.categoryid
	WHEN 1 THEN 'Beverages'
	WHEN 2 THEN 'Condiments'
	WHEN 3 THEN 'Confections'
	WHEN 4 THEN 'Dairy Products'
	ELSE 'Unknown Category'
   END AS categoryname
FROM Production.Products a;

---- searched CASE form
SELECT a.orderid, a.custid, a.val,
  CASE 
   WHEN a.val < 1000.00 THEN 'Less than 1000'
   WHEN a.val BETWEEN 1000.00 and 3000.00 THEN 'BETWEEN 1000 and 3000'
   WHEN a.val > 3000.00 THEN 'More than 3000'
  END AS valuecategory
FROM Sales.OrderValues a;

-- NULL mark
SELECT a.custid, a.country, a.region, a.city
FROM Sales.Customers AS a
WHERE region <> N'WA'
   OR region IS NULL;

-- Date and Time Functions 
SELECT @@LANGUAGE

---- Current Date and Time
SELECT 
	GETDATE() AS [GETDATE],
	CURRENT_TIMESTAMP AS [CURRENT_TIMESTAMP],
	GETUTCDATE() AS [GETUTCDATE],
	SYSDATETIME() AS [SYSDATETIME],
	SYSUTCDATETIME() AS [SYSUTCDATETIME],
	SYSDATETIMEOFFSET() AS [SYSDATETIMEOFFSET];

SELECT 
	CAST(SYSDATETIME() AS DATE) AS [current_date],
	CAST(SYSDATETIME() AS TIME) AS [current_time];

---- CAST, CONVERT and PARSE
SELECT CAST('20090212' AS DATE);
SELECT CAST(CURRENT_TIMESTAMP AS DATE); -- extract only DATE part
SELECT CAST(CURRENT_TIMESTAMP AS TIME); -- extract only TIME part

SELECT CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112);
SELECT CAST(CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112) AS DATETIME);
SELECT CONVERT(CHAR(12), CURRENT_TIMESTAMP, 114);
SELECT CAST(CONVERT(CHAR(12), CURRENT_TIMESTAMP, 114) AS DATETIME);

---- SWITCHOFFSET Function 
SELECT SYSDATETIMEOFFSET();
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '-05:00');
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00'); -- UTC time

---- TODATETIMEOFFSET Function
SELECT CAST('20090212' AS DATETIME);
SELECT CAST('20090212' AS DATETIMEOFFSET);
SELECT TODATETIMEOFFSET('20090212', '+08:00');

---- DATEADD Function 
SELECT DATEADD(year, 1, '20090212');

---- DATEDIFF Function
SELECT DATEDIFF(day, '20080212', '20090212');
---- Set the time component of CURRENT_TIMESTAMP to midnight for versions prior to SQL Server 2008
SELECT CURRENT_TIMESTAMP;
SELECT DATEDIFF(day, '20010101', CURRENT_TIMESTAMP);
SELECT DATEADD(day, 
			   DATEDIFF(day, '20010101', CURRENT_TIMESTAMP), 
			   '20010101'); -- treat '20010101' as anchor date
---- Get the first day of month using DATEADD and DATEDIFF
SELECT DATEDIFF(month, '20010101', CURRENT_TIMESTAMP);
SELECT DATEADD(month, 
			   DATEDIFF(month, '20010101', CURRENT_TIMESTAMP),
			   '20010101'); -- set anchor date as the first day of month
---- Get the last day of month 
SELECT DATEADD(month, 
			   DATEDIFF(month, '19991231', CURRENT_TIMESTAMP),
			   '19991231'); -- set anchor date as the last day of month





---- DATEPART(part, dt_val) Function
SELECT DATEPART(month, '20090212');
---- YEAR, MONTH, and DAY Functions: abbreviateions for the DATEPART Function 
SELECT 
	YEAR('20090212') AS theyear,
	MONTH('20090212') AS themonth,
	DAY('20090212') AS theday;
---- DATENAME(part, dt_val) Function -- language dependent 
SELECT DATENAME(month, '20090212');
---- ISDATE(string) Function
SELECT ISDATE('20090212'); -- is date
SELECT ISDATE('20090230'); -- not a date
---- FROMPARTS Functions
SELECT 
	DATEFROMPARTS(2012, 2, 12),
	DATETIME2FROMPARTS(2012, 2, 12, 13, 30, 5, 1, 7)
------ DATETIMEFROMPARTS(y, m, d, h, m, s, milliseconds)
------ DATETIMEOFFSETFROMPARTS(y, m, d, h, m, s, fractions, hour_offset, minute_offset, precision)
------ SMALLDATETIMEFROMPARTS(y, m, d, h, m)
------ TIMEFROMPARTS(h, m, s, fractions, precision)

---- EOMONTH(dt_vl, [,months_to_add] Function: return end of the month
SELECT EOMONTH(SYSDATETIME());
SELECT EOMONTH(SYSDATETIME(), -2);





-- Catalog Views
---- list all tables in a databse along with their schema names.
SELECT SCHEMA_NAME(schema_id) AS table_schema_name, name AS table_name
FROM sys.tables;

SELECT SCHEMA_NAME(schema_id) FROM sys.schemas;
SELECT * FROM sys.columns
WHERE object_id = OBJECT_ID(N'Sales.Orders');
-- Note:OBJECT_ID() Function transfers table names to object ID

-- Information Schema Views
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = N'BASE TABLE';

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = N'Sales'
  AND TABLE_NAME = N'Orders';

-- System stored procedures and functions
---- sp_tables: return list of objects can be queried in the current table
EXEC sys.sp_tables;
---- sp_help: accepts an object name as input and returns multiple result sets 
---- with general information about he object.
EXEC sys.sp_help @objname = N'Sales.Orders';
---- sp_columns: returns information about columns in an object 
EXEC sys.sp_columns
  @table_name = N'Orders',
  @table_owner = N'Sales';
---- sp_helpconstraint: returns information about constraints in an object.
EXEC sys.sp_helpconstraint
  @objname = N'Sales.Orders';

---- SERVERPROPERTY function returns the requested property of the current instance.
SELECT SERVERPROPERTY('ProductLevel');
SELECT DATABASEPROPERTYEX(N'TSQL2012', 'Collation');
SELECT OBJECTPROPERTY(OBJECT_ID(N'Sales.Orders'), 'TableHasPrimaryKey');
SELECT COLUMNPROPERTY(OBJECT_ID(N'Sales.Orders'), N'shipcountry', 'AllowNull');