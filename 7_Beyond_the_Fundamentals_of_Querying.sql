-- T-SQL Fundamentals
-- Chapter 7 Beyond the Fundamentals of Querying 
USE TSQLV4;
GO
-- 1. Window Functions
-- Example: compute the running total values for each employee and month
SELECT empid, ordermonth, val, 
	SUM(val) OVER(PARTITION BY empid
								ORDER BY ordermonth
								ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
								) AS runval
FROM Sales.EmpOrders;
-- Ranking Winow Functions
SELECT orderid, custid, val, 
	ROW_NUMBER() OVER(ORDER BY val) AS rowsum,
	RANK()       OVER(ORDER BY val) AS rank,
	DENSE_RANK() OVER(ORDER BY val) AS dense_rank,
	NTILE(100)   OVER(ORDER BY val) AS ntile
FROM Sales.OrderValues
ORDER BY val;

SELECT orderid, custid, val,
	ROW_NUMBER() OVER(PARTITION BY custid ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;

-- Offset Window Functions 
SELECT custid, orderid, val,
	LAG(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS prevval,
	LEAD(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS nextval
FROM Sales.OrderValues;

SELECT custid, orderdate, val,
	FIRST_VALUE(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS firstval,
	LAST_VALUE(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

-- Aggregate Windwo Functions 
SELECT orderid, custid, val,
	SUM(val) OVER() as totalvalue,
	SUM(val) OVER(PARTITION BY custid) AS custtotalvalue
FROM Sales.OrderValues;

SELECT orderid, custid, val,
	100. * val / SUM(val) OVER() AS pctall,
	100. * val / SUM(val) OVER(PARTITION BY custid) AS pctcust
FROM Sales.OrderValues;
---- Calculate running totals
SELECT empid, ordermonth, val, 
	SUM(val) OVER(PARTITION BY empid ORDER BY ordermonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;


-- 2. Pivoting Data 
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
GO 

CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	orderdate DATE NOT NULL,
	empid INT NOT NULL,
	custid VARCHAR(5) NOT NULL,
	qty INT NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
GO 

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid, qty)
VALUES
  (30001, '20140802', 3, 'A', 10),
  (10001, '20141224', 2, 'A', 12),
  (10005, '20141224', 1, 'B', 20),
  (40001, '20150109', 2, 'A', 40),
  (10006, '20150118', 1, 'C', 14),
  (20001, '20150212', 2, 'B', 12),
  (40005, '20160212', 3, 'A', 10),
  (20002, '20160216', 1, 'C', 20),
  (30003, '20160418', 2, 'B', 15),
  (30004, '20140418', 3, 'C', 22),
  (30007, '20160907', 3, 'D', 30);
GO 

SELECT * FROM dbo.Orders;

SELECT empid, custid, sum(qty) as sum_qty
FROM dbo.Orders
GROUP BY empid, custid;

---- Pivoting with Standard SQL
SELECT empid,
	SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
	SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
	SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
	SUM(CASE WHEN custid = 'D' THEN qty END) AS D
FROM dbo.Orders
GROUP BY empid;

---- Pivoting with PIVOT operator
SELECT empid, A, B, C, D 
FROM(SELECT empid, custid, qty FROM dbo.Orders) AS D
	PIVOT(SUM(qty) FOR custid IN (A, B, C, D)) AS P;
	-- NOTE: IN (A, B, C, D) is column name not value in here.

SELECT custid, [1], [2], [3]
FROM (SELECT empid, custid, qty FROM dbo.Orders) AS D
	PIVOT(SUM(qty) FOR empid IN ([1], [2], [3])) AS P;


SELECT n
FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS Nums(n);

-- Unpivoting Data

IF OBJECT_ID('dbo.EmpCustOrders', 'U') IS NOT NULL DROP TABLE dbo.EmpCustOrders;
CREATE TABLE dbo.EmpCustOrders
(
	empid INT NOT NULL
	CONSTRAINT PK_EmpCustOrders PRIMARY KEY,
	A VARCHAR(5) NULL,
	B VARCHAR(5) NULL,
	C VARCHAR(5) NULL,
	D VARCHAR(5) NULL
);

INSERT INTO dbo.EmpCustOrders(empid, A, B, C, D)
SELECT empid, A, B, C, D
FROM (SELECT empid, custid, qty FROM dbo.Orders) AS D
	PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

SELECT * FROM dbo.EmpCustOrders;

---- Unpivoting with Standard SQL 
---- producting multiple copies 
SELECT * 
FROM dbo.EmpCustOrders
	CROSS JOIN (VALUES('A'),('B'),('C'),('D')) AS Custs(custid);
----extracting elements and eliminate irrelevant intersections. 
SELECT * FROM (
	SELECT empid, custid,
		CASE custid
			WHEN 'A' THEN A -- refer to column A
			WHEN 'B' THEN B 
			WHEN 'C' THEN C
			WHEN 'D' THEN D 
		END AS qty
	FROM dbo.EmpCustOrders
		CROSS JOIN (VALUES('A'),('B'),('C'),('D')) AS Custs(custid)
) AS D
WHERE qty IS NOT NULL;

---- Unpivoting with the Native T-SQL UNPIVOT Operator 
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	UNPIVOT(qty FOR custid IN(A, B, C, D)) AS U;

-- Grouping sets
SELECT empid, custid, SUM(qty) 
FROM dbo.Orders
GROUP BY empid, custid

UNION ALL

SELECT empid, NULL, SUM(qty)  -- Add NULL as placeholder.
FROM dbo.Orders
GROUP BY empid;

----GROUPING SETS
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS
	(
		(empid, custid),
		(empid),
		(custid),
		()
	);
----CUBE
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);
----ROLLUP
SELECT 
	YEAR(orderdate) AS orderyear,
	MONTH(orderdate) AS ordermonth,
	DAY(orderdate) AS orderday,
	SUM(qty) as sumqty
FROM dbo.Orders
GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));
----GROUPING Function
SELECT 
	GROUPING(empid) AS grpemp,
	GROUPING(custid) AS grpcust,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);
----GROUPING_ID Function
SELECT 
	GROUPING_ID(empid, custid) AS groupingset,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);
