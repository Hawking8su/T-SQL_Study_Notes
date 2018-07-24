# T-SQL Fundamentals
# Chapter 4 Subqueries

SQL supports writing queries within queries, or nesting queries (outer queries + subqueries). When you use subqueries, you avoid the need for separate steps in your solutions that store intermmediate query results in variables.

A subquery can be either self-contained and correlated.
- Subquery: independent of the outer query.
- Correlated query: has dependency on the outer query.

Subquried can return a scalar or multiple values.

## Self-Contained Subqueries
### Self-Contained Scalar Subquery Examples
A scalar subquery is a subquery that returns a single value.
For example, to query the Orders table and return information about the order that has the maximum order ID in the table:
```SQL
-- Using variables
DECLARE @maxid AS INT = (SELECT MAX(orderid) FROM Sales.Orders);

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = @maxid;

-- Using subquries
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = (SELECT MAX(O.orderid) FROM Sales.Orders O)

```
For a scalar subquery to be valid, it must return no more than one value. The key for a scalar subqueries:
- write correct subqueries
- use equality operator: = (VS IN for multivalued Subqueries)

### Self-Contained Multivalued Subquery Examples
A multivalued subquery is a subquery that returns multiple values as a single column -- use IN predicate.

For example, to query order IDs of orders placed by employees with a last name starting with D.
```SQL
SELECT orderid
FROM Sales.Orders
WHERE empid IN
	(SELECT E.empid
	FROM HR.Employees AS E
	WHERE E.lastname LIKE 'D%');
```

The same result can also be achieved using JOINs:
```SQL
SELECT O.orderid
FROM HR.Employees AS E
	JOIN Sales.Orders AS O
	  ON E.empid = O.empid
WHERE E.lastname LIKE N'D%';
```

> My approach is to first write the solution query for the specified task an intuitive form, and if performance is not satisfactory, one of my tuning approaches is to try query revisions.

```SQL
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
	(SELECT O.custid  -- DISTINCT is not necessary for performance purpose,
	FROM Sales.Orders O);

```
Note: DISTINCT is not necessary for performance purpose, because the database engine is smart enough to consider removing duplicates without you asking it to do so explicitly.
```SQL
-- Example 4: return all individual order IDs that are missing between the
-- minimum and maximum in the table.
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
```
## Correlated Subqueries
Correlated subqueries are subquries that refers to attributes from the table that appears in the outer query. This means that the subquery is dependent on the outer query and cannot be invoked independently.

```SQL
---- Example: return orders with the maximum order ID for each customer.
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS O1
WHERE orderid =
	(SELECT MAX(O2.orderid)
	FROM Sales.Orders AS O2
	WHERE O2.custid = O1.custid); -- correlated
```

To debug correlated subqueries you need to substitute the correlation with a constant, and after ensuring that the code is correct, substitute the constant with the correlation.

Example 2: return for each order the percentage that the current order value is of the total values of all of the customer's order.

```SQL
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
WHERE OV2.custid = 2;
```
You can also solve this problem using window functions (see Chapter 7).
> It's always a good idea to try to come up with several solutions to each problem, because the different solutions will usually vary in complexity and performance.

### The EXISTS Predicate
EXISTS predicate accepts a subquery as input and returns TRUE if the subquery returns any rows and FALSE otherwise. You can negate it with the NOT logical operator.
```SQL
---- Example: return customers from Spain who placed orders
SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.country = N'Spain'
  AND EXISTS
	    (SELECT * FROM Sales.Orders AS O
		WHERE O.custid = C.custid);

```
Benefits of using EXISTS:
- allows you to intuitively phrase English-like queries.
- lends itself to good performance optimization.

Notes about using EXISTS:
- unlike most other cases, it's logically not a bad practice to use an asterisk(\*) in the SELECT list of the subquery int he context of the EXISTS predicate.
- EXISTS uses two-value logic and not three-value logic. -- there is no situation where it is unkown whether a query returns any rows.

## Beyond the Fundamentals
### Returning Previous or Next Values

```SQL
---- Return previous orderid = return the max orderid that is smaller than the current one.
SELECT orderid, orderdate, empid, custid,
	(SELECT MAX(O1.orderid)
	FROM Sales.Orders AS O2
	WHERE O2.orderid < O1.orderid) AS prevorderid
FROM Sales.Orders AS O1
```
Note: because there is no order before the first, the subquery returned a NULL for the first order.
```SQL
---- Return next orderid = retrun the min orderid that is larger than the current one.
SELECT orderid, orderdate, empid, custid,
	(SELECT MIN(O2.orderid)
	FROM Sales.Orders AS O2
	WHERE O2.orderid > O1.orderid) AS nextorderid
FROM Sales.Orders AS O1;
```
Note: SQL Server 2012 introduces new window functions called LAG and LEAD that allow the return of an element from a "previous" or "next" row based on specific ordering (see Chapter 7).

### Running Aggregates
```SQL
---- Example: return for each year the order year, quantity, and running total
---- quantity over the years.
SELECT orderyear, qty,
	(SELECT SUM(O2.qty)
	FROM Sales.OrderTotalsByYear AS O2
	WHERE O2.orderyear <= O1.orderyear) AS runqty
FROM Sales.OrderTotalsByYear AS O1
ORDER BY orderyear;
```

### Dealing with Misbehaving Subqueries

#### NULL Trouble

#### Substitution Errors in Subquery Column Names
