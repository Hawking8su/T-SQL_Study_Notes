-- T-SQL Fundamentals
-- Chapter 3 Joins: Exercises

-- 1-1 Cross join
SELECT E.empid, E.firstname, E.lastname, N1.n
FROM HR.Employees AS E
  CROSS JOIN (SELECT n FROM dbo.Nums WHERE n <= 5) AS N1;

-- Or
SELECT E.empid, E.firstname, E.lastname, N.n
FROM HR.Employees AS E
  CROSS JOIN dbo.Nums AS N
WHERE N.n <= 5
ORDER BY n, empid;

-- 1-2 
---- First, create a sequence of dates from '20160612' to '20160616'
SELECT DATEADD(day, n-1, '20160612') AS dt 
FROM dbo.Nums
WHERE n <= DATEDIFF(day, '20160612', '20160616') + 1 
ORDER BY dt;
-- Second, cross join 2 tables.
SELECT E.empid, N.dt
FROM HR.Employees AS E
	CROSS JOIN 
		(SELECT DATEADD(day, n-1, '20160612') AS dt 
		FROM dbo.Nums
		WHERE n <= DATEDIFF(day, '20160612', '20160616') + 1) AS N
ORDER BY empid;

-- Or 
SELECT E.empid, DATEADD(day, n-1, '20160612') AS dt -- show n as transfered date
FROM HR.Employees AS E
	CROSS JOIN dbo.Nums AS D -- Join table as n
WHERE D.n <= DATEDIFF(day, '20160612', '20160616') + 1
ORDER BY empid, dt

-- 2 Outer join + Multiple tables
SELECT 
	C.custid, 
	COUNT(O.orderid) AS numorders,
	SUM(OD.qty) AS totalqty
FROM Sales.Customers C
  LEFT OUTER JOIN Sales.Orders O
		ON C.custid = O.custid
	LEFT OUTER JOIN Sales.OrderDetails OD
		ON O.orderid = OD.orderid
WHERE C.country = 'USA'
GROUP BY C.custid;

-- 3 
SELECT C.custid, C.companyname, O.orderid, O.orderdate 
FROM Sales.Customers C
	LEFT OUTER JOIN Sales.Orders O
	ON C.custid = O.custid

-- 4 
SELECT C.custid, C.companyname, O.orderid, O.orderdate 
FROM Sales.Customers C
	LEFT OUTER JOIN Sales.Orders O
	ON C.custid = O.custid
WHERE O.orderdate IS NULL;

-- 5 
SELECT C.custid, C.companyname, O.orderid, O.orderdate 
FROM Sales.Customers C
	LEFT OUTER JOIN Sales.Orders O
	ON C.custid = O.custid
WHERE O.orderdate = '20150212';

-- 6 
SELECT C.custid, C.companyname, O1.orderid, O1.orderdate 
FROM Sales.Customers C
	LEFT OUTER JOIN 
		(SELECT custid, orderid, orderdate
		FROM Sales.Orders
		WHERE orderdate = '20150212') AS O1
	ON C.custid = O1.custid;

-- Or: Add the filter in ON clause, not in WHERE (as it's final)
-- Note, ON clauses are processed from left to right. 
SELECT C.custid, C.companyname, O.orderid, O.orderdate 
FROM Sales.Customers C
	LEFT OUTER JOIN Sales.Orders O
	ON C.custid = O.custid
	AND O.orderdate = '20150212';

-- 7
SELECT C.custid, C.companyname, 
	CASE 
		WHEN O1.orderid IS NULL THEN 'No'
		ELSE 'Yes'
	END AS [HasOrderOn20150202]
FROM Sales.Customers C
	LEFT OUTER JOIN 
		(SELECT custid, orderid, orderdate
		FROM Sales.Orders
		WHERE orderdate = '20150212') AS O1
	ON C.custid = O1.custid;
