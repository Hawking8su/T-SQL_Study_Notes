-- T-SQL Fundamentals
-- Chapter 6 Set Operators Exercises
USE TSQLV4;

-- 1 
SELECT 1 AS n
UNION ALL SELECT 2 
UNION ALL SELECT 3 
UNION ALL SELECT 4 
UNION ALL SELECT 5 
UNION ALL SELECT 6 
UNION ALL SELECT 7 
UNION ALL SELECT 8 
UNION ALL SELECT 9
UNION ALL SELECT 10;

-- 2 Has order in January but not in Feburary.
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101'
	AND orderdate <  '20160201'
EXCEPT 
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201'
	AND orderdate <  '20160301'

-- 3 Has order in both January and Feburary
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101'
	AND orderdate <  '20160201'
INTERSECT 
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201'
	AND orderdate <  '20160301';

-- 4 
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101'
	AND orderdate <  '20160201'
INTERSECT 
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201'
	AND orderdate <  '20160301'
EXCEPT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20150101'
	AND orderdate <  '20160101';

-- 5
WITH C AS
( 
	SELECT 1 AS sortcol, country, region, city
	FROM HR.Employees
	UNION ALL
	SELECT 2 AS sortcol, country, region, city
	FROM Production.Suppliers
) 
SELECT country, region, city 
FROM C
ORDER BY sortcol, country, region, city;