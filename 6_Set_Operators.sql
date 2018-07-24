-- T-SQL Fundamentals
-- Chapter 6 Set Operators 
USE TSQLV4;

-- 1. UNION
---- UNION ALL
SELECT country, region, city FROM HR.Employees
UNION ALL 
SELECT country, region, city FROM Sales.Customers;

---- UNION (DISTINCT)
SELECT country, region, city FROM HR.Employees
UNION 
SELECT country, region, city FROM Sales.Customers;

-- 2. INTERSECT
SELECT country, region, city FROM HR.Employees
INTERSECT 
SELECT country, region, city FROM Sales.Customers;

-- INTERSECT + ROW_NUMBER = INTERSECT ALL
SELECT * FROM HR.Employees
-- Note: ROW_NUMBER() must have ORDER BY clause. 
-- Using ORDER BY (SELECT <constant>) is one of several ways to tell SQL 
-- that order doesn't matter.  
SELECT ROW_NUMBER() 
	OVER(PARTITION BY country, region, city
			 ORDER BY (SELECT 0)) AS rowsum,
	country, region, city
FROM HR.Employees
INTERSECT
SELECT ROW_NUMBER() 
	OVER(PARTITION BY country, region, city
			 ORDER BY (SELECT 0)) AS rowsum,
	country, region, city
FROM Sales.Customers;
-- To not return row numbers: CTEs + INTERSET ALL
WITH INTERSECT_ALL AS
(
	SELECT ROW_NUMBER() 
		OVER(PARTITION BY country, region, city
				 ORDER BY (SELECT 0)) AS rowsum,
		country, region, city
	FROM HR.Employees
	INTERSECT
	SELECT ROW_NUMBER() 
		OVER(PARTITION BY country, region, city
				 ORDER BY (SELECT 0)) AS rowsum,
		country, region, city
	FROM Sales.Customers
)
SELECT country, region, city 
FROM INTERSECT_ALL;
-- 3. EXCEPT 
SELECT country, region, city FROM HR.Employees
EXCEPT
SELECT country, region, city FROM Sales.Customers;

-- 4. Precedence
---- return locations that are supplier locations but not (locations 
---- that are both employee and customer locations).
SELECT country, region, city FROM Production.Suppliers
EXCEPT
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- 5. Circumventing Unsupported Logical Phases
SELECT country, COUNT(*) AS numlocations
FROM (SELECT country, region, city FROM HR.Employees
			UNION
			SELECT country, region, city FROM Sales.Customers) AS U
GROUP BY country;
---- return two most recent orders for thos employee with an employee ID of 3 or 5.
SELECT empid, orderid, orderdate 
FROM (SELECT TOP(2) empid, orderid, orderdate
			FROM Sales.Orders
			WHERE empid = 3 
			ORDER BY orderdate DESC, orderid DESC) AS D1

UNION ALL

SELECT empid, orderid, orderdate 
FROM (SELECT TOP(2) empid, orderid, orderdate
			FROM Sales.Orders
			WHERE empid = 5
			ORDER BY orderdate DESC, orderid DESC) AS D2;