-- T-SQL Fundamentals
-- Chapter 4 Subqueries: Exercises
USE TSQLV4;

-- 1 Return orders placed on the last day of activity.
SELECT O1.orderdate, O1.orderdate, O1.custid, O1.empid
FROM Sales.Orders O1
WHERE O1.orderdate = 
	(SELECT MAX(O2.orderdate) 
	FROM Sales.Orders O2);


-- 2 Return all orders placed by the cutomer(s) who placed the highest number of orders.
SELECT COUNT(O2.orderid) 
FROM Sales.Orders O2
GROUP BY O2.custid;

SELECT TOP 10 * FROM Sales.Orders;

-- 3 Return employees who did not place orders on or after May 1, 2008
SELECT E.empid, E.firstname, E.lastname
FROM HR.Employees E
WHERE E.empid NOT IN
	(SELECT O.empid
	FROM Sales.Orders O
	WHERE O.orderdate >= '20160501');

-- 4 Return countries where there are customers but not employees.
SELECT DISTINCT C.country
FROM Sales.Customers C
WHERE C.country NOT IN
	(SELECT E.country
	FROM HR.Employees E)
ORDER BY C.country;

-- Trial
SELECT TOP 50 * FROM Sales.Orders;
SELECT shippeddate, shipperid, shipaddress FROM Sales.Orders
WHERE shipperid = '3'
AND shipaddress LIKE '%\%'
OR shipaddress LIKE 'L%';

SELECT shippeddate, shipperid, shipaddress FROM Sales.Orders
WHERE shipperid = '3'
AND shipaddress LIKE '%\%'
OR 1 = 1;
