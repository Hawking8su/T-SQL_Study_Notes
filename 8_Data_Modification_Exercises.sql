-- T-SQL Fundamentals
-- Chapter 8 Data Modification Exercises

USE TSQLV4;
-- 1
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
CREATE TABLE dbo.Customers
(
	custid INT NOT NULL PRIMARY KEY,
	companyname NVARCHAR(40) NOT NULL,
	country NVARCHAR(15) NOT NULL,
	region NVARCHAR(15) NULL,
	city NVARCHAR(15) NOT NULL
);
---- INSERT + VALUES
INSERT INTO dbo.Customers(custid, companyname, country, region, city)
	VALUES(100, 'Coho Winery', 'USA', 'WA', 'Redmond');
---- INSERT + SELECT + WHERE EXISTS
INSERT INTO dbo.Customers(custid, companyname, country, region, city)
	SELECT C.custid, C.companyname, C.country, C.region, C.city 
	FROM Sales.Customers AS C
	WHERE EXISTS
		(SELECT * FROM Sales.Orders AS O
		 WHERE O.custid = C.custid);
---- SELECT INTO
IF OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE dbo.Orders;
SELECT * 
INTO dbo.Orders 
FROM Sales.Orders AS O
WHERE O.orderdate >= '20140101' 
	AND O.orderdate < '20170101'

-- 2
DELETE FROM dbo.Orders 
OUTPUT deleted.orderid, deleted.orderdate
WHERE orderdate < '20140801';

-- 3
DELETE FROM O  
FROM dbo.Orders AS O
	JOIN dbo.Customers AS C
		ON O.custid = C.custid
WHERE C.country = N'Brazil';

-- 4
UPDATE dbo.Customers
	SET region = N'<None>'
OUTPUT 
	inserted.custid,
	deleted.region AS oldregion,
	inserted.region AS newregion
WHERE region IS NULL;

-- 5 
UPDATE O 
	SET O.shipcountry = C.country,
			O.shipregion = C.region,
			O.shipcity = C.city
FROM dbo.Orders AS O
JOIN dbo.Customers AS C
  ON O.custid = C.custid
WHERE C.country = N'UK';

-- 6 clean up 
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;