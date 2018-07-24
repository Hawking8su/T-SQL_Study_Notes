-- T-SQL Fundamentals
-- Chapter 3 Joins
USE TSQLV4;

-- Cross Joins
SELECT C.custid, E.empid
FROM Sales.Customers C
  CROSS JOIN HR.Employees E
ORDER BY custid;

-- Self Cross Join
SELECT 
  E1.empid, E1.firstname, E1.lastname,
  E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
  CROSS JOIN HR.Employees AS E2

-- Produce tables of numbers
USE TSQLV4;
IF OBJECT_ID('dbo.Digits', 'U') IS NOT NULL DROP TABLE dbo.Digits;
CREATE TABLE dbo.Digits(digit INT NOT NULL PRIMARY KEY);

INSERT INTO dbo.Digits(digit)
	VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

SELECT * FROM dbo.Digits;
---- Produce a sequence of integers in the range 1 through 1000. 
SELECT D1.digit * 100 + D2.digit * 10 + D3.digit + 1 AS n 
FROM         dbo.Digits D1
  CROSS JOIN dbo.Digits D2
  CROSS JOIN dbo.Digits D3
ORDER BY n;

-- Inner Join
SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E
  JOIN Sales.Orders AS O
    ON E.empid = O.empid;

-- Composite Join 
USE TSQLV4;
IF OBJECT_ID('Sales.OrderDetailsAudit', 'U') IS NOT NULL
    DROP TABLE Sales.OrderDetailsAudit;
CREATE TABLE Sales.OrderDetailsAudit
(
    lsn INT NOT NULL IDENTITY,
    orderid INT NOT NULL,
    productid INT NOT NULL,
    dt DATETIME NOT NULL,
    loginname sysname NOT NULL,
    columnname sysname NOT NULL,
    oldval SQL_VARIANT,
    newval SQL_VARIANT,
    CONSTRAINT PK_OrderDetailsAudit PRIMARY KEY(lsn),
    CONSTRAINT FK_OrderDetailsAudit_OrderDetails
    FOREIGN KEY(orderid, productid)
    REFERENCES Sales.OrderDetails(orderid, productid)
);
SELECT * FROM Sales.OrderDetailsAudit;

SELECT OD.orderid, OD.productid, OD.qty,
    ODA.dt, ODA.loginname, ODA.oldval, ODA.newval
FROM Sales.OrderDetails AS OD
JOIN Sales.OrderDetailsAudit AS ODA
  ON OD.orderid = ODA.orderid
  AND OD.productid = ODA.productid
WHERE ODA.columnname = N'qty';

-- Non-Equi Joins
SELECT 
  E1.empid, E1.firstname, E1.lastname,
  E2.empid, E2.firstname, E2.lastname
FROM HR.Employees E1
  JOIN HR.Employees E2 
    ON E1.empid < E2.empid;

-- Multi-Join Queries
SELECT 
  C.custid, C.companyname, O.orderid,
  OD.productid, OD.qty
FROM Sales.Customers AS C
  JOIN Sales.Orders AS O 
    ON C.custid = O.custid
  JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid;

-- Outer Join 
SELECT C.custid, C.companyname, O.orderid
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
  ON C.custid = O.custid 
WHERE orderid IS NULL;

-- Including Missing Values
---- 1. Create a sequence of all dates 
SELECT * FROM dbo.Nums;
SELECT DATEADD(day, n-1, '20140101') AS orderdate
FROM dbo.Nums
WHERE n <= DATEDIFF(day, '20140101', '20161231') + 1 
ORDER BY orderdate;

SELECT YEAR(orderdate), MONTH(orderdate)
FROM Sales.Orders
GROUP BY YEAR(orderdate), MONTH(orderdate)
ORDER BY YEAR(orderdate), MONTH(orderdate);

---- 2. Extend the previous query using left outer join
SELECT 
  DATEADD(day, Nums.n - 1, '20140101') AS orderdate,
  O.orderid, O.custid, O.empid
FROM dbo.Nums
  LEFT OUTER JOIN Sales.Orders AS O 
    ON DATEADD(day, Nums.n - 1, '20140101') = O.orderdate
WHERE Nums.n <= DATEDIFF(day, '20140101', '20161231') + 1
ORDER BY orderdate;