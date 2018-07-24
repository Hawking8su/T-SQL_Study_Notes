-- Chapter 2 Single-Table Queries
-- Exercises

USE TSQLV4;

-- 1
SELECT O.orderid, O.orderdate, O.custid, O.empid
FROM Sales.Orders O
WHERE O.orderdate >= '20150601' AND O.orderdate < '20150701';

-- Check for all year and month of all data
SELECT 
	YEAR(O.orderdate) AS orderyear, 
    MONTH(O.orderdate) AS ordermonth
FROM Sales.Orders O
GROUP BY YEAR(O.orderdate), MONTH(O.orderdate)
ORDER BY orderyear, ordermonth;

-- 2. Last day of month
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);

-- 3
SELECT empid, lastname, firstname 
FROM HR.Employees
WHERE lastname LIKE '%s%s%';

-- 4
SELECT orderid, (qty * unitprice) AS totalvalue 
FROM Sales.OrderDetails 
WHERE (qty * unitprice) > 10000
ORDER BY (qty * unitprice) DESC;
-- Check those top orders' orderdetails, notice that 
-- one orderid might include multiple products. 
SELECT orderid, qty, unitprice
FROM Sales.OrderDetails
WHERE orderid IN (10865, 10981, 10889,10353);
-- Therefore, the totalvalue should be SUM(qty * unitprice)
-- the requirement should be a HAVING clause not a WHERE clause
-- since it works on groups of rows not individual row.
SELECT orderid, SUM(qty * unitprice) AS totalvalue
FROM Sales.OrderDetails
GROUP BY orderid 
HAVING SUM(qty * unitprice) > 10000
ORDER BY totalvalue DESC;

SELECT * FROM Sales.OrderDetails;

-- 5
SELECT TOP 3 O.shipcountry, AVG(O.freight) AS avgfreight
FROM Sales.Orders O
WHERE O.orderdate >= '20150101' AND O.orderdate < '20160101'
GROUP BY O.shipcountry
ORDER BY avgfreight DESC;

-- 6 
SELECT O.custid, O.orderdate, O.orderid, 
	ROW_NUMBER() OVER(PARTITION BY O.custid 
					  ORDER BY O.orderdate) AS rownum 
FROM Sales.Orders O
ORDER BY O.custid;

-- 7 
SELECT * FROM HR.Employees;
---- simple CASE form
SELECT empid, lastname, firstname, titleofcourtesy,
	CASE titleofcourtesy
      WHEN 'Ms.'  THEN 'Female'
	  WHEN 'Mrs.' THEN 'Female'
	  WHEN 'Mr.'  THEN 'Male'
	  ELSE  'Unknown'
	END AS gender
FROM HR.Employees;
---- searched CASE form
SELECT empid, lastname, firstname, titleofcourtesy,
	CASE 
	  WHEN titleofcourtesy IN ('Ms.','Mrs.') THEN 'Female'
	  WHEN titleofcourtesy = 'Mr.'           THEN 'Male'
	  ELSE										  'Unknown'
	END AS gender
FROM HR.Employees

-- 8 How to get NULL marks to sort last: USE CASE in ORDER BY
SELECT * FROM Sales.Customers;

SELECT custid, region 
FROM Sales.Customers
ORDER BY 
  CASE WHEN region IS NULL THEN 1 ELSE 0 END,
  region;








