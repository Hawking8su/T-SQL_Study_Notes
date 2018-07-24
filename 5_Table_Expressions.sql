-- T-SQL Fundamentals
-- Chapter 5 Table Expressions
USE TSQLV4;

-- 1. Derived Tables
SELECT * 
FROM (SELECT custid, companyname
			FROM Sales.Customers
			WHERE country = N'USA') AS USACusts;

-- Inline form: improve code maintainability by retaining only one
-- copy of YEAR(orderyear) expression.
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts 
FROM (SELECT YEAR(orderdate) AS orderyear, custid
      FROM Sales.Orders) AS D
GROUP BY orderyear;

-- Using arguments: return the number of distinct customers per year
-- whose orders were handled by the input employee. 
DECLARE @empid AS INT = 3;
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts 
FROM (SELECT YEAR(orderdate) AS orderyear, custid
			FROM Sales.Orders
			WHERE empid = @empid) AS D
GROUP BY orderyear;

-- Problem1 Nesting: return order years and the number of customers handled in 
-- each year only for years in which more than 70 customers were handled.
SELECT orderyear, numcusts
FROM (SELECT orderyear, COUNT(DISTINCT custid) as numcusts
			FROM (SELECT YEAR(orderdate) AS orderyear, custid
						FROM Sales.Orders) AS D1
			GROUP BY orderyear) D2
WHERE numcusts > 70;
---- Or: using HAVING clause
SELECT orderyear, COUNT(DISTINCT custid) as numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
			FROM Sales.Orders) AS D
GROUP BY orderyear
HAVING COUNT(DISTINCT custid) > 70;

-- Problem2 Multiple Reference: calculate growth of distinct
-- customers each order year.
SELECT Cur.orderyear, 
		Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
		Cur.numcusts - Prv.numcusts AS growth
FROM (SELECT YEAR(orderdate) AS orderyear, 
					   COUNT(DISTINCT custid) AS numcusts
			FROM Sales.Orders
			GROUP BY YEAR(orderdate)) AS Cur
LEFT OUTER JOIN 
		 (SELECT YEAR(orderdate) AS orderyear, 
			       COUNT(DISTINCT custid) AS numcusts
			FROM Sales.Orders
			GROUP BY YEAR(orderdate)) AS Prv
ON Cur.orderyear = Prv.orderyear + 1;

-- 2. Common Table Expressions (CTEs)
-- inline form
WITH C AS
(
	SELECT YEAR(orderdate) AS orderyear, custid 
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C 
GROUP BY orderyear;
-- Using arguments in CTEs 
DECLARE @empid AS INT = 3;
WITH C AS 
(
	SELECT YEAR(orderdate) AS orderyear, custid 
	FROM Sales.Orders
	WHERE empid = @empid
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;
-- Defining Multiple CTEs
WITH C1 AS 
(
	SELECT YEAR(orderdate) AS orderyear, custid 
	FROM Sales.Orders
),
C2 AS 
(
	SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
	FROM C1 
	GROUP BY orderyear
)
SELECT orderyear, numcusts
FROM C2
WHERE numcusts > 70;

-- Multiple Reference in CTEs 
WITH YearlyCount AS
(
	SELECT YEAR(orderdate) AS orderyear,
				 COUNT(DISTINCT custid) AS numcusts
	FROM Sales.Orders
	GROUP BY YEAR(orderdate)
)
SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS Cur
LEFT OUTER JOIN YearlyCount AS Prv
ON Cur.orderyear = Prv.orderyear + 1;

-- Recursive CTEs
---- return information about an employee and all of the employee's
---- subordinates in all levels
WITH EmpsCTE AS
(
	-- anchor member
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 2

	UNION ALL
	-- recursive member
	SELECT C.empid, C.mgrid, C.firstname, C.lastname
	FROM EmpsCTE AS P
		JOIN HR.Employees AS C
			ON C.mgrid = P.empid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsCTE;

-- 3. Views 
USE TSQLV4;
IF OBJECT_ID('Sales.USACusts') IS NOT NULL
	DROP VIEW Sales.USACusts;
GO
CREATE VIEW Sales.USACusts
AS
SELECT 
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO 

SELECT * FROM Sales.USACusts;

-- Views and ORDER BY Clause
ALTER VIEW Sales.USACusts
AS 
SELECT TOP(100) PERCENT 
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO

SELECT custid, companyname, region 
FROM Sales.USACusts;
-- View Options
---- ENCRYPTION Option
ALTER VIEW Sales.USACusts 
AS
SELECT 
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO 

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS 
SELECT 
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO 
SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));
EXEC sp_helptext 'Sales.USACusts';

---- SCHEMABINDING Option
ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS 
SELECT 
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO 
---- error will be returned when dropping binded columns in Sales.Customers.
ALTER TABLE Sales.Customers DROP COLUMN address;

---- CHECK OPTION 
---- Without CHECK OPTION, you can insert rows through the view with 
---- customers from countries other than the U.S.
INSERT INTO Sales.USACusts(
	companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax)
VALUES(
	N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE',
	N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');
-- you will not see the inserted row in view
SELECT custid, companyname, country
FROM Sales.USACusts
WHERE companyname LIKE N'%ABCDE%';
-- you will see it in the base table. 
SELECT custid, companyname, country
FROM Sales.Customers
WHERE companyname LIKE N'%ABCDE%';

-- With CHECK OPTION
ALTER VIEW Sales.USACusts WITH SCHEMABINDING 
AS
SELECT 
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
WITH CHECK OPTION;
GO 

-- Clean up 
DELETE FROM Sales.Customers
WHERE custid > 91;
IF OBJECT_ID('Sales.USACusts') IS NOT NULL 
	DROP VIEW Sales.USACusts;

-- 4. Inline Table-Valued Functions
USE TSQLV4;
IF OBJECT_ID('dbo.GetCustOrders') IS NOT NULL
	DROP FUNCTION dbo.GetCustOrders; 
GO
CREATE FUNCTION dbo.GetCustOrders
	(@cid AS INT) RETURNS TABLE
AS 
RETURN 
	SELECT orderid, custid, empid, orderdate, requireddate
	FROM Sales.Orders
	WHERE custid = @cid;
GO

SELECT orderid, custid
FROM dbo.GetCustOrders(1) AS O;

SELECT O.orderid, O.custid, OD.productid, OD.qty
FROM dbo.GetCustOrders(1) AS O
	JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

-- Clean up 
IF OBJECT_ID('dbo.GetCustOrders') IS NOT NULL
	DROP FUNCTION dbo.GetCustOrders;