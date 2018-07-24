# T-SQL Fundamentals
## Chapter 7 Beyond the Fundamentals of Querying
Contents:
- Window Functions
- Pivoting and Unpivoting data
- Grouping sets

### Window Functions
A *window function* is a function that, for each row, computes a scalar result value based on a calculation against a subset of the rows from the underlying query.
- The subset of rows is known as a window
- The OVER clause provide the window specification

Advantages of using window functions:
- Compared with grouped queries：grouped queries cause you to lose details of data, while window functions has an OVER clause that defines the set of rows for the function to work with, without imposing the same arrangment of rows on the query itself. In other words:
  - grouped queries defines the sets, or groups, in the query, and therefore all calculations in the query have to be done in the context of those groups.
  - With window functions, the set is defined for each function, nor fo the entire query.
- Compared with subqueries: subquery starts from a fresh view of the data, so you might need to repeat a lot of logic. In contrast, a window function is applied to a subset of rows from the underlying query's result set -- not a fresh view of the data.
- The ability to define order, when applicable. Note the ordering specification for the window function, if applicable, is different from the ordering specification for presentation.

```SQL
-- Example: compute the running total values for each employee and month
SELECT empid, ordermonth, val,
	SUM(val) OVER(PARTITION BY empid
								ORDER BY ordermonth
								ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
								) AS runval
FROM Sales.EmpOrders
```

The window specification in the OVER clause has 3 main parts:
  1. Partitioning -- PARTITION BY: restricts the window to the subset of rows that share the same values in the partitioning columns as in the current row.
  2. Ordering -- ORDER BY: the window ordering is what gives meaning to window framing. Don't confuse this with presentation ordering.
  3. Framing -- ROWS BETWEEN ... AND ...: filters a frame of rows from the window partition between the two specified delimiters.

Note that because the starting point of a window function is the underlying query's result set, and the underlying query's result set is generated only when you reach the SELECT phase, window functions are allowed only in the SELECT and ORDER BY clauses of a query.

Window functions also lend themselves to very efficient optimization for common-use cases.

#### Ranking Window Functions
SQL Server supports 4 raning functions:
- ROW_NUMBER: assigns incrementing sequential integers tot he rows in the result set, based on specified logical order. If the ORDER BY list is non-unique, the query is non-deterministic.
- RANK: treat ties in the ordering values the same way, and indicate how many lower values
- DENSE_RANK: similar to RANK, but indicate how many *distinct* lower values.
- NTILE(n): associate the rows in the result with tiles (equally sized groups of rows) by assigning a tile number to each row. If the number of rows doesn't divide evenly by the number of tiles, an extra row is added to each of the first tiles from the remainder.

```SQL
SELECT orderid, custid, val,
	ROW_NUMBER() OVER(ORDER BY val) AS rowsum,
	RANK()       OVER(ORDER BY val) AS rank,
	DENSE_RANK() OVER(ORDER BY val) AS dense_rank,
	NTILE(100)   OVER(ORDER BY val) AS ntile
FROM Sales.OrderValues
ORDER BY val;
```

Ranking functions support window partition clauses.
```SQL
SELECT orderid, custid, val,
	ROW_NUMBER() OVER(PARTITION BY custid ORDER BY val) AS rownum
FROM Sales.OrderValues
```
Remember that window ordering has nothing to do with presentation ordering and does not change the nature of the result being relational.

Evaluation sequence:
  - GROUP BY clause
  - SELECT clause
  - DISTINCT clause
```SQL
-- DISTINCT clause has no effect
SELECT DISTINCT val, ROW_NUMBER OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues;

-- GROUP BY is processed before SELECT ROW_NUMBER()
SELECT val, ROW_NUMBER OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;
```
#### Offset Window Functions
SQL Server supports 4 offset functions:
- LAG and LEAD: allow you to obtain an element from a row that is at a certain offset from the current row within the partition, based on indicated ordering. Support window partition and window order clauses.
```SQL
-- LAG(col, offset, default value)
SELECT custid, orderid, val,
	LAG(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS prevval,
	LEAD(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS nextval
FROM Sales.OrderValues;

```
- FIRST_VALUE and LAST_VALUE: allow you to return an element from the first and last rows in the window frame, respectively.
```SQL
SELECT custid, orderdate, val,
	FIRST_VALUE(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS firstval,
	LAST_VALUE(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;
```

#### Aggregate Window Functions
One of the great adavantages of window functions is that by enabling you to return detail elements and aggregate them in the same row, they also enable you to write expressions that mix detail and aggregates.
```SQL
SELECT orderid, custid, val,
	SUM(val) OVER() as totalvalue, -- OVER with empty parentheses exposes a window of all rows.
	SUM(val) OVER(PARTITION BY custid) AS custtotalvalue
FROM Sales.OrderValues;
---- Compare with SUM + GROUP BY, SUM + OVER window function will not cause you to loose details of data
SELECT custid, SUM(val)
FROM Sales.OrderValues
GROUP BY custid;

SELECT orderid, custid, val,
	100. * val / SUM(val) OVER() AS pctall,
	100. * val / SUM(val) OVER(PARTITION BY custid) AS pctcust
FROM Sales.OrderValues;
---- Calculate running totals
SELECT empid, ordermonth, val,
	SUM(val) OVER(PARTITION BY empid ORDER BY ordermonth ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

```

SQL Server support other delimiters for the ROWS window frame unit. For example, to capture all rows from 2 rows before the current row and through one row ahead, you would use ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING.

### Pivoting Data
Pivoting data involves rotating data from a state of rows to a state of columns, possibly aggregating values along the way. In many cases, pivoting of data is handled by the presentation layer.

Every pivoting request involves three logical processing phases:
  - a grouping phase with an associated grouping or on rows elements.
  - a spreading phase with an associated spreading or on cols element.
  - an aggregation phase with an associated aggregation element and aggregate function.

Preparation:
```SQL
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
```

#### Pivoting with Standard SQL
- Grouping phase: achieved with GROUP BY clause
  `GROUP BY empid`
- Spreading phase: achieved in the SELECT clause with a CASE expression.
  `CASE WHEN custid = 'A' THEN qty END`
  Note that if you don't know the values that you need to spread ahead of time, you need to use dynamic SQL to construct the query string and execute it.
- Aggregation phase: achieve by applying relevant aggregation function to the result of each CASE function.
  `SUM(CASE WHEN custid = 'A' THEN qty END) AS A`

Complete example:
```SQL
SELECT empid,
	SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
	SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
	SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
	SUM(CASE WHEN custid = 'D' THEN qty END) AS D
FROM dbo.Orders
GROUP BY empid;
```

#### Pivoting with the Native T-SQL PIVOT Operator
The PIVOT operator operates in the context of the FROM clause of a query like other table operators (i.e. JOIN).

The General form of a query with the PIVOT operators:
```
SELECT ...
FROM <source_table_or_table_expression>
  PIVOT(<agg_func>(agg_element) FOR <spread_element> IN (<list_of_target_columns>)) AS <result_table_alias>
```

It is important to note that with the PIVOT operator, you do not explicitly specify the grouping elements, removing the need for GROUP BY in the query. The PIVOT operator figures out the grouping elements implicitly as all attributes from the source table that were not specified as either the spreading element or the aggregation element.

To ensure that the source table has no attributes besides the grouping, spreading, and aggregation elements, you can not apply the PIVOT operator to the original table directly, but instead to a table expression that includes only the attributes representing the pivoting elements and no others.
```SQL
SELECT empid, A, B, C, D
FROM(SELECT empid, custid, qty FROM dbo.Orders) AS D
	PIVOT(SUM(qty) FOR custid IN (A, B, C, D)) AS P;
  -- note: IN (A, B, C, D) is column name not value in here.
  -- note: you cannot use a dynamic table in the IN() clause, so cannot pivot table when you don't know the column names.


SELECT custid, [1], [2], [3]
FROM (SELECT empid, custid, qty FROM dbo.Orders) AS D
	PIVOT(SUM(qty) FOR empid IN ([1], [2], [3])) AS P;
  -- note: when identifiers are irregular you need to delimit them with square brackets.
```

It's strongly recommended that you never operate on the base table directly, because you never know whether new columns will be added to the table in the future, renderin your queries incorrect.



### Unpivoting Data
Unpivoting is a technique to rotate from a state of columns to a state of rows.
#### Unpivoting with Standard SQL
Three logical processing phases:
- Producing copies: producing multiple copies of each source row -- one for each column that you need to unpivot.
- Extracting elements
- Eliminating irrelevant intersections
```SQL
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
) AS
WHERE qty IS NOT NULL;
```

#### Unpivoting with Native T-SQL UNPIVOT Operator
The general form of a query with the UNPIVOT operator:
```
SELECT ...
FROM <source_table>
  UNPIVOT(<target col to hold source col values>
    FOR <target col to hold source col names> IN <list of source columns>)) AS <result_table_alias>

```

```SQL
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	UNPIVOT(qty FOR custid IN(A, B, C, D)) AS U;
```
Note:
- a pivoted table cannot be unpivoted back to the original state, because some detail was lost in the pivoting.
- an unpivoted table can be pivoted to the

### Grouping Sets
A grouping set is simply a set of attributes by which you group.

Traditionally, if you want to a single unified result set with the aggregated data for multiple grouping sets, you need to use UNION ALL to combine single grouing sets.
```SQL
SELECT empid, custid, SUM(qty)
FROM dbo.Orders
GROUP BY empid, custid

UNION ALL

SELECT empid, NULL, SUM(qty)  -- Add NULL as placeholder.
FROM dbo.Orders
GROUP BY empid;
```
This approach has 2 problems: the length of the code and the performance. SQL Server supports 3 subclauses to define multiple grouping sets in the same query: *GROUPING SETS, CUBE, and ROLLUP* of the GROUP BY clause. And GROUPING and GROUPING_ID functions.

#### The GROUPING SETS subclause
```SQL
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
```
#### The CUBE Subclause
CUBE(a, b, c, d) = GROUPING SETS((a,b,c), (a,b), (a,c), (b,c), (a), (b), (c), ()). -- a power set.
```SQL
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);
```

#### The ROLLUP Subclause
ROLLUP assumes a hierarchy among the input members and produces all grouping sets that make sense considering the hierarchy.
ROLLUP(a, b, c) => assume a>b>c: GROUPING SETS((a,b,c), (a,b), (a), ())
```SQL
SELECT
	YEAR(orderdate) AS orderyear,
	MONTH(orderdate) AS ordermonth,
	DAY(orderdate) AS orderday,
	SUM(qty) as sumqty
FROM dbo.Orders
GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));
```

#### The GROUPING and GROUPING_ID Functions
Until now, you need to rely on the NULL marks to figure out the association between result rows and grouping sets. However, if a grouping column is defined as allowing NULL marks in the table, you cannot tell for sure whether a NULL in the result set originated from the data or is a placeholder for a nonparticipating member in a grouping set.

GROUPING function accepts a name of a column and returns 0 if it is a member of the current grouping set and 1 otherwise.
```SQL
SELECT
	GROUPING(empid) AS grpemp,
	GROUPING(custid) AS grpcust,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

```

GROUPING_ID(a, b, c, d) function returns an integer bitmap in which each bit represents a different input element--(0*8 + 0*4 + 0*2 +0*1).
```SQL
SELECT
	GROUPING_ID(empid, custid) AS groupingset,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);
```
