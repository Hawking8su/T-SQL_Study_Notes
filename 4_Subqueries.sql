-- T-SQL Fundamentals
-- Chapter 4 Subqueries
USE TSQLV4;

-- Self-contained scalar subquries
---- Using variables
DECLARE @maxid AS INT = (SELECT MAX(orderid) FROM Sales.Orders);

SELECT orderid, orderdate, empid, custid 
FROM Sales.Orders
WHERE orderid = @maxid;

---- Using scalar subquries
SELECT orderid, orderdate, empid, custid 
FROM Sales.Orders
WHERE orderid = (SELECT MAX(O.orderid) FROM Sales.Orders O);

-- Self-contained multivalued subquries 
-- Example 1
SELECT orderid
FROM Sales.Orders 
WHERE empid IN
	(SELECT E.empid 
	FROM HR.Employees AS E
	WHERE E.lastname LIKE 'D%');
--- Or using joins
SELECT O.orderid
FROM HR.Employees AS E
	JOIN Sales.Orders AS O
		ON E.empid = O.empid
WHERE E.lastname LIKE N'D%';

-- Example 2: return orders placed by cutomers from the U.S.
SELECT custid, orderid, orderdate, empid 
FROM Sales.Orders
WHERE custid IN
	(SELECT C.custid
	FROM Sales.Customers AS C
	WHERE C.country = N'USA');

-- Example 3: return customers who did not place any orders.
SELECT C.custid, C.companyname
FROM Sales.Customers C
WHERE C.custid NOT IN
	(SELECT DISTINCT O.custid
	FROM Sales.Orders O);

-- Example 4: return all individual order IDs that are missing between the minimum and maximum in the table. 
USE TSQLV4;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
CREATE TABLE dbo.Orders(orderid INT NOT NULL CONSTRAINT PK_Orders PRIMARY KEY);

INSERT INTO dbo.Orders(orderid)
	SELECT orderid
	FROM Sales.Orders
	WHERE orderid % 2 = 0;

SELECT n
FROM dbo.Nums -- helper table 
WHERE n BETWEEN (SELECT MIN(orderid) FROM dbo.Orders) -- scalar
						AND (SELECT MAX(orderid) FROM dbo.Orders) -- scalar
  AND n NOT IN (SELECT orderid FROM dbo.Orders);      -- multivalued

DROP TABLE dbo.Orders;

-- Correlated Subqueries 
---- Example 1: return orders with the maximum order ID for each customer.
SELECT custid, orderid, orderdate, empid 
FROM Sales.Orders AS O1
WHERE orderid = 
	(SELECT MAX(O2.orderid)
	FROM Sales.Orders AS O2
	WHERE O2.custid = O1.custid); -- correlated

---- Example 2: return for each order the percentage that the current order value 
---- is of the total values of all of the customer's order. 

SELECT OV1.custid, OV1.orderid, OV1.val,
	CAST(100. * val / (SELECT SUM(OV2.val) AS sumval
										FROM Sales.OrderValues AS OV2
										WHERE OV2.custid = OV1.custid) 
			AS NUMERIC(5,2)) AS pct
FROM Sales.OrderValues OV1
ORDER BY custid, orderid;

---- Debug subquery 
SELECT SUM(OV2.val) AS sumval
FROM Sales.OrderValues AS OV2
WHERE OV2.custid = 2

-- The EXISTS Predicate
---- Example: return customers from Spain who placed orders
SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.country = N'Spain'
  AND EXISTS 
	    (SELECT * FROM Sales.Orders AS O
			WHERE O.custid = C.custid);
 
-- Return Previous or Next Values
---- Return previous orderid = return the max orderid that is smaller than the current one.
SELECT orderid, orderdate, empid, custid,
	(SELECT MAX(O2.orderid)
	FROM Sales.Orders AS O2
	WHERE O2.orderid < O1.orderid) AS prevorderid
FROM Sales.Orders AS O1;
---- Return next orderid = retrun the min orderid that is larger than the current one.
SELECT orderid, orderdate, empid, custid,
	(SELECT MIN(O2.orderid)
	FROM Sales.Orders AS O2
	WHERE O2.orderid > O1.orderid) AS nextorderid
FROM Sales.Orders AS O1;
---- Running Aggregates 
SELECT orderyear, qty, 
	(SELECT SUM(O2.qty)
	FROM Sales.OrderTotalsByYear AS O2
	WHERE O2.orderyear <= O1.orderyear) AS runqty
FROM Sales.OrderTotalsByYear AS O1
ORDER BY orderyear;

