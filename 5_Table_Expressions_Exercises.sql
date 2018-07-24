-- T-SQL Fundamentals
-- Chapter 5 Table Expressions Excercises

-- 1-1
SELECT empid, MAX(orderdate) AS maxorderdate
FROM Sales.Orders
GROUP BY empid;

-- 1-2 
SELECT O1.empid, O.orderdate, O.orderid, O.custid
FROM (SELECT empid, MAX(orderdate) AS maxorderdate
			FROM Sales.Orders
			GROUP BY empid) AS O1
LEFT OUTER JOIN Sales.Orders AS O
ON O1.empid = O.empid
AND O1.maxorderdate = O.orderdate
ORDER BY empid DESC;

-- 2-1 
SELECT orderid, orderdate, custid, empid, 
	ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rowsum
FROM Sales.Orders;
-- 2-2
WITH C AS
(
	SELECT orderid, orderdate, custid, empid, 
		ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rowsum
	FROM Sales.Orders
)
SELECT orderid, orderdate, custid, empid, rowsum 
FROM C
WHERE rowsum BETWEEN 11 AND 20;

-- 3 Recursive CTE
WITH EmpsCTE AS
(
	-- anchor member
	SELECT empid, lastname, firstname, title, mgrid
	FROM HR.Employees
	WHERE empid = 9

	UNION ALL
	
	-- recursive member
	SELECT H.empid, H.lastname, H.firstname, H.title, H.mgrid
	FROM EmpsCTE AS E
	JOIN HR.Employees AS H
		ON E.mgrid = H.empid
)
SELECT empid, mgrid, lastname, firstname, title
FROM EmpsCTE;



-- 4 View
USE TSQLV4;
IF OBJECT_ID('Sales.VEmpOrders') IS NOT NULL DROP VIEW Sales.VEmpOrders;
GO
CREATE VIEW Sales.VEmpOrders WITH SCHEMABINDING
AS 
SELECT O.empid, YEAR(O.orderdate) AS orderyear, SUM(OD.qty) AS qty
FROM Sales.Orders AS O
LEFT OUTER JOIN Sales.OrderDetails AS OD
	ON O.orderid = OD.orderid
GROUP BY O.empid, YEAR(O.orderdate);
GO

SELECT * FROM Sales.VEmpOrders ORDER BY empid, orderyear;