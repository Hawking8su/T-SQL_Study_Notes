# T-SQL Fundamentals
## Chapter 5 Table Expressions
A table expresion is a named query expression that represents a valid relational table. You can use table expressions in data manipulation statements much like you use other tables. Microsoft SQL Server supports four types of table expressions:
- derived tables
- common table expressions (CTEs)
- views
- inline table-valued functions (inline TVFs).

Table expressions are not physically materialized anywhere--they are virtual. When you query a table expression, the inner query gets unnested. In other words, the outer query and the inner query are merged into one query directly against the underlying objects.

The benefits of using table expressions are typically related to the logical aspects of your code not to performance.

### Derived Tables
Derived tables are defined in the FROM clause of an outer query. Their scope of existence is the outer query.

An Example:
```SQL
SELECT *
FROM (SELECT custid, companyname
	  FROM Sales.Customers
	  WHERE country = N'USA') AS USACusts;
```

A query must meet 3 requirements to be valid to define a table expression of any kind:
1. Order is not guaranteed.

    For this reason, standard SQL disallows an ORDER BY clause in queries that are used to define table expressions, unless the ORDER BY serves another purpose besides presentation.
2. All columns must have names.
3. All column names must be unique.

**All 3 requirements have to do with the fact that the table expression is supposed to represent a relation.**

#### Assigning Column Aliases
One of the benefits of using table expresions is that, in any clause of the outer query, you can refer to column aliases that were assigned in the SELECT clause of the inner query.

For example, the query below doesn't work because GROUP BY clause is processed before SELECT clause.
```SQL
SELECT
    YEAR(orderdate) AS orderyear,
    COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY orderyear;
```
You can solve this problem by using `YEAR(orderdate)` again in the GROUP BY clause. However, if the expression is much longer, maintainin 2 copies of expressions could hurt code readability and maintainability. To solve the problem in a way that requires only one copy of the expression, you can use a table expression like below.
```SQL
-- Inline form
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
      FROM Sales.Orders) AS D
GROUP BY orderyear;

-- External form
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate), custid
      FROM Sales.Orders) AS D(orderyear, custid)
GROUP BY orderyear;

```
As it's shown above, there are 2 forms of defining column aliases of a derived table. It's generally recommended to use the inline form for 2 reasons: easy to debug and easy to read. However, in some cases, when you want to treat the table expression like a "black box" and focus more attention on the column aliases, the external form might more convenient to work with.

#### Using Arguments

```SQL
-- Using arguments: return the number of distinct customers per year
-- whose orders were handled by the input employee.
DECLARE @empid AS INT = 3;
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
			FROM Sales.Orders
			WHERE empid = @empid) AS D
GROUP BY orderyear;
```

#### Nesting
If you need to define a derived table by using query that itself refers to a derived table, you end up nesting derived tables. Nesting is a problematic aspect of programming in general, because it tends to complicate the code and reduce its readability.

#### Multiple References
Another problematic aspect of derived table stems from the fact that derived tables are defined in the FROM clause of the outer query and not prior to the outer query. As far as the FROM clause of the outer query is concerned, the derived table doesn't exist yet; therfore, if you need to refer to multiple instances of the derived table, you can't. Instead, you have to define multiple derived tables based on the same query.
```SQL
SELECT Cur.orderyear,
		Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
		Cur.numcusts - Prv.numcusts AS growth
FROM (SELECT YEAR(orderdate) AS orderyear,
			COUNT(DISTINCT custid) AS numcusts
	  FROM Sales.Orders
	  GROUP BY YEAR(orderdate)) AS Cur
LEFT OUTER JOIN
	 (SELECT YEAR(orderdate) AS orderyear,
			 COUNT(DISTINCT custid) AS numcusts
	  FROM Sales.Orders
	  GROUP BY YEAR(orderdate)) AS Prv
ON Cur.orderyear = Prv.orderyear + 1;
```

### Common Table Expressions (CTEs)

General form of CTEs:
```
WITH  <CTE_Name> [(<target_column_list>)]
AS
(
	<inner_query_defining_CTE>
)
<outer_query_against_CTE>;
```
The inner query defining the CTE must follow all requirements mentioned earlier to be valid to define a table expression.

#### Assigning Column Aliases in CTEs
```SQL
-- inline form
WITH C AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;

-- external form
WITH C(orderyear, custid) AS
(
	SELECT YEAR(orderdate), custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;
```

#### Using Arguments in CTEs
```SQL
DECLARE @empid AS INT = 3;
WITH C AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
	WHERE empid = @empid
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;
```

#### Defining Multiple CTEs
One of the advantages of using CTEs over derived tables is that if you need to refer to one CTE from another, you don't end up nesting them as you do with derived tables. Instead, you simply define multiple CTEs separated by commas under the same WITH statement.
```SQL
WITH C1 AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
),
C2 AS
(
	SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
	FROM C1
	GROUP BY orderyear
)
SELECT orderyear, numcusts
FROM C2
WHERE numcusts > 70;
```
This modular approach substantially improves the readability and maintainability of the code compared to the nested derived table approach.

#### Multiple References in CTEs
Another advantage of using CTEs is that you can refer to multiple instances of the same CTE.
```SQL
WITH YearlyCount AS
(
	SELECT YEAR(orderdate) AS orderyear,
				 COUNT(DISTINCT custid) AS numcusts
	FROM Sales.Orders
	GROUP BY YEAR(orderdate)
)
SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS Cur
LEFT OUTER JOIN YearlyCount AS Prv
ON Cur.orderyear = Prv.orderyear + 1;
```

#### Recursive CTEs
General form:
```
WITH <CTE_Name>[(<target_column_list>)] AS
(
	<anchor_member>
	UNION ALL
	<recursive_member>
)
<outer_query_against_CTE;
```
- The anchor member is a query that returns a valid relational result table. It is invoked only once.
- The recursive member is a query that has a reference to the CTE name.
Note:
1. The first time the the recursive member is invoked, the anchor member returned.
2. In each subsequent invocation of the recursive member, the reference to the CTE name represents the result set returned by the previous invocation of the recursive member.
3. The recursive member has no explicit recursion termination check -- the termination check is implicit. The recursive member is invoked repeatedly until it returns an empty set or exceeds some limit.

```SQL
---- return information about an employee and all of the employee's
---- subordinates in all levels
WITH EmpsCTE AS
(
	-- anchor member
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 2

	UNION ALL
	-- recursive member
	SELECT C.empid, C.mgrid, C.firstname, C.lastname
	FROM EmpsCTE AS P
		JOIN HR.Employees AS C
			ON C.mgrid = P.empid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsCTE;
```
The recursive member is invoked repeatedly, and in each invocation it returns the next level of subordinates.

Note: the recursive member can potentially be invoked an infinite number of times. AS safty measure, by default SQL Server restricts the number of times that the recursive member can be invoked to 100. You can change the default maximum recursion limit by specifying the hint `OPTION(MAXRECURSION n)`.

### Views
Derived tables and CTEs are not reusable. However, Views and inline-valued functions (inline TVFs) are two reusable types of table expressions--their definitions are stored as database objects.

Because a view is an object in the databse, you can control access to the view with permissions just as you can with other objects. that can be queried (these permissions include SELECT, INSERT, UPDATE, and DELETE permissions).

Note that the general recommendation to avoid using SELECT * has specific relevance in the context of views. The columns are enumerated in the complied form of the view, and new table columns will not be automatically added to the view.

Example:
```SQL
USE TSQLV4;
IF OBJECT_ID('Sales.USACusts') IS NOT NULL
	DROP VIEW Sales.USACusts;
GO
CREATE VIEW Sales.USACusts
AS
SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

SELECT * FROM Sales.USACusts;
```

#### Views and the ORDER BY Clause
Remember that a presentation ORDER BY clause is not allowed in the query defining a table expression because there's no order among the rows of a relational table. If you need to return rows from a view sorted for presentation purpose, you should specify a presentation ORDER BY clause in the outer query against the view.

SQL Server allows the ORDER BY clause in table or view definition in three exceptional cases: TOP, OFFSET-FETCH, or FOR XML. In these cases, ORDER BY clause serves a filtering purpose instead of presentation purpose, so presentation order is not guaranteed.
```SQL
ALTER VIEW Sales.USACusts
AS
SELECT TOP(100) PERCENT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO

SELECT custid, companyname, region
FROM Sales.USACusts;
```
Key points about ORDER BY:
	- Any order of the rows in the output is considered valid, and no specific order is guaranteed.
	- Do not confuse the behavior of a query that is used to define a table expression with a query that isn't.

#### View Options
##### ENCRYPTION Option
```SQL
---- without ENCRYPTION
ALTER VIEW Sales.USACusts  
AS
SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO
-- Return text that defines the View.
SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));
-- With ENCRYPTION
ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS
SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO
-- Return NULL
SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));
-- OR use sp_helptext to look for object defition.
EXEC sp_helptext 'Sales.USACusts';
```
##### The SCHEMABINDING Option
This option is available to views and UDFs; it binds the schema of referenced objects and columns to the schema of the referencing object. It indicates that referenced objects cannot be dropped and that referenced columns cannot be dropped or altered.
```SQL
ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS
SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO
---- error will be returned when dropping binded columns in Sales.Customers.
ALTER TABLE Sales.Customers DROP COLUMN address;
```

Note that, to support the SCHEMABINDING option, the object definition must meet some technical requirements:
	1. The query is not allowed to use * in the SELECT clause.
	2. Must use schema-qualified two-part names when refering objects.

In general, creating your object with SCHEMABINDING option is a good practice.

##### The CHECK OPTION Option
The purpose of CHECK OPTION is to prevent modifications through the view that conflict with the view's filter.
```SQL
---- Without CHECK OPTION, you can insert rows through the view with
---- customers from countries other than the U.S.
INSERT INTO Sales.USACusts(
	companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax)
VALUES(
	N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE',
	N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');
-- you will not see the inserted row in view
SELECT custid, companyname, country
FROM Sales.USACusts
WHERE companyname LIKE N'%ABCDE%';
-- you will see it in the base table.
SELECT custid, companyname, country
FROM Sales.Customers
WHERE companyname LIKE N'%ABCDE%';
```
If you want to prevent modifications that conflict with the view's filter, add WITH CHECK OPTION at the end of the query defining the view.
```SQL
-- With CHECK OPTION
ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS
SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
WITH CHECK OPTION;
GO
```

### Inline Table-Valued Functions
Inline TVFs are reusable table expressions that support input parameters. In all respects except for the support for input parameters, inline TVFs are similar to views.
```SQL
USE TSQLV4;
IF OBJECT_ID('dbo.GetCustOrders') IS NOT NULL
	DROP FUNCTION dbo.GetCustOrders;
GO
CREATE FUNCTION dbo.GetCustOrders
	(@cid AS INT) RETURNS TABLE -- defines input parameter @cid
AS
RETURN
	SELECT orderid, custid, empid, orderdate, requireddate
	FROM Sales.Orders
	WHERE custid = @cid;
GO
-- Remeber to provide an alias for the table expression.
SELECT orderid, custid
FROM dbo.GetCustOrders(1) AS O;

```

### The APPLY Operator
