# Chapter 3 Joins

The FROM clause of a query is the first clause to be logically processed, and within the FROM clause, table operators operate on input tables. SQL Server supports 4 table opertors--JOIN(standard), APPLY, PIVOT, and UNPIVOT.

Three fundamental types of joins with different logical processing phases:
- Cross Join: Cartesian Product
- Inner Join: Cartesian Product + Filter
- Outer Join: Cartesian Product + Filter + Add Outer Rows

Logical and Physical query processing phase might be different :
- Logical query processing: a generic series of logical steps that for any specific query produces the correct result.
- Physical query processing: the way the query is processed by the RDBMS engine in practice.-- based on relational algebra.

## Cross Joins
Simplest type of join--only one logical processing phase: a Cartesian product--each row from one table is matched with all rows from the other=> m * n rows.

### ANSI SQL-92 Syntax
*Recommended*

```SQL
SELECT C.custid, E.empid
FROM Sales.Customers C
  CROSS JOIN HR.Employees E
ORDER BY custid;
```
Note:
- You need specify *CROSS JOIN* between two tables.
- The result table has 819 rows = 91(Customers) * 9(Employees).
- The purpose of the prefixes is to facilitate the identification of columns in an unambiguous manner. Also note that if you assign an alias to a table, it is invalid to use the full table name as a column prefix.

### ANIS SQL-89 Syntax
```SQL
SELECT C.custid, E.empid
FROM Sales.Customers C, HR.Employees E;
```

### Self Cross Joins
You can join multiple instances of the same table. Note, in a self join, aliasing table is not optional.

### Producing Tables of Numbers
By using CROSS JOINs, you can produce the sequence of integers(an extremely powerful tool) in a very efficient manner.

Example: To produce a sequence of integers in the range 1 through 1000:
1. First, create a helper table from 1 to 10.
2. Self Cross Join 1 to 10 three times, each time represent different different digits.
```SQL
USE TSQLV4;
-- Create helper table from 1 to 10
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
```

## Inner Joins
Two logical query processing phases: Cartesin product (based on Cross Join) + Filter (based on ON predicate).   
Note the three-valued predicate logic: On clause returns only rows of TRUE, filtering out rows of FALSE and UNKNOWN.

### ANSI SQL-92 Syntax
The INNER keyword is optional, because an inner join is the default of join.
```SQL
SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E
  JOIN Sales.Orders AS O
    ON E.empid = O.empid;
```
### ANSI SQL-89 Syntax
```SQL
SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E, Sales.Orders AS O
WHERE E.empid = O.empid;
```

### Inner join safty
It is strongly recommended that you stick to the ANSI SQL-92 join syntax because:
- When you intend to write an INNER JOIN but forget to specify the ON clause, ANSI SQL-92 will return an error, but SQL-89 will not (making it harder to debug).
- Better readability.

## More Join Examples

### Composite Joins
A composite join is simply a join based on a predicate that involves more than one attribute.
```SQL
FROM dbo.Table1 AS T1
  JOIN dbo.Table2 AS T2
    ON T1.col1 = T2.col1
    AND T1.col2 = T2.col2;
-- Example:
USE TSQL2012;
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

SELECT OD.orderid, OD.productid, OD.qty,
    ODA.dt, ODA.loginname, ODA.oldval, ODA.newval
FROM Sales.OrderDetails AS OD
JOIN Sales.OrderDetailsAudit AS ODA
  ON OD.orderid = ODA.orderid
  AND OD.productid = ODA.productid
WHERE ODA.columnname = N'qty';
```

### Non-Equi Joins
When a join condition involves any operator besides equality, the join is said to be a non-equi join.

Note: standard SQL supports a concept called *natural join*, which represents an inner join based on a match between columns with the same name in both sides. However, T-SQL doesn't have an implementation of a natural join.

### Multi-Join Queries
Multi-Join queries can be used to join multiple tables. In general, when more than one table operators appears in the FROM clause, the table operators are logically processed from left to right.
```SQL
SELECT
  C.custid, C.companyname, O.orderid,
  OD.productid, OD.qty
FROM Sales.Customers AS C
  JOIN Sales.Orders AS O
    ON C.custid = O.custid
  JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid;
```

## Outer Joins
Three logical query processing phases: Cartesin product (based on Cross Join) + Filter (based on ON predicate) + Add outer rows of the preserved table.
The 3rd logical processing phase of an outer join identifies the rows from the preserved table that did not find matches in the other table on the ON predicate. Using NULL marks as placeholders.
```SQL
SELECT C.custid, C.companyname, O.orderid
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
  ON C.custid = O.custid
WHERE orderid IS NULL;
```
A common question about outer joins is whether to specify a predicate in the ON or WHERE clause of a query.
- ON clause: processed IN FROM phase, determine how two tables match each other.
- WHERE clause: processed after FROM phase, determine filters after tables are joined together.

Note: The choice of which attribute from the nonpreserved side of the join to filter is important. You should choose an attribute that can only have a NULL when the row is an outer row and not othterwise (for example, not a NULL originating from the base table), because using an attribute with NULL marks as a join column will generating NULL marks that cannot be differentiated from the source. For this purpose, three cases are safe to consider:
- a primary key column
- a join column
- a column defined as NOT NULL

### Beyond the Fundamentals of Outer Joins
#### Including Missing Values
For example, suppose you need to query all orders from the Orders table. You need to ensure that you get at least one row in the output for each date in the range January 1, 2014 through December 31, 2016.   
To solve this problem:
1. First, create an auxiliary table that can used to generate a sequence of all dates.
2. Extend the previous query using left outer join to join all dates and Orders table.
```SQL
---- 1. Create a sequence of all dates
SELECT * FROM dbo.Nums;
SELECT DATEADD(day, n-1, '20140101') AS orderdate
FROM dbo.Nums
WHERE n <= DATEDIFF(day, '20140101', '20161231') + 1
ORDER BY orderdate;

---- 2. Extend the previous query using left outer join
SELECT
  DATEADD(day, Nums.n - 1, '20140101') AS orderdate,
  O.orderid, O.custid, O.empid
FROM dbo.Nums
  LEFT OUTER JOIN Sales.Orders AS O
    ON DATEADD(day, Nums.n - 1, '20140101') = O.orderdate
WHERE Nums.n <= DATEDIFF(day, '20140101', '20161231') + 1
ORDER BY orderdate;
```
#### Filtering Attributes from the Nonpreserved Side of an Outer Join
When you need to review code involving outer joins to look for logical bugs, one of the things you should examine is WHERE clause. If the predicate in the WHERE clause refers to an attribute from the nonpreserved side of the join, it's usually an indication of a bug. This is because attributes from the nonpreserved side of the join are all NULL marks in outer rows, and a WHERE clause filters UNKNOWN out. In other words, it's as if the join type logically becomes an inner join.

Example:
```SQL
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers C
  LEFT OUTER JOIN Sales.Orders O
    ON C.custid = O.custid
WHERE O.orderdate >= '20150101'
```
#### Using Outer Joins in a Multi-Join Query

#### Using the COUNT Aggregate with Outer Joins
