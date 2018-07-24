# Chapter 2 Single-Table Queries

This chapter introduces you to the fundamentals of the SELECT statement, focusing for now on queries against a single table.

## Elements of the SELECT Statement

The purpose of the a SELECT statement is to query tables, apply some logical manipulation, and return a result.

Sample Query
```SQL
USE TSQLV4;

SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS numbers
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1
ORDER BY empid, orderyear;
```

In most programming languages, the lines of code are processed in the order that they are written. In SQL, things are different. Even though the SELECT clause appears first in the query, it is logically processed almost last. The clauses are logically processed in the following order: FROM --> WHERE --> GROUP BY --> HAVING --> SELECT --> ORDER BY.

You cannot write the query in correct logical order. You have to start with the SELECT clause. This is because the designers of SQL envisioned a declarative language with which you provide your request in an English-like manner.

*Recommendation:* Terminate all statements with a semicolon because it is standard. It improves the code readability.

### The FROM Clause

The FROM clause is the very first query clause that is logically processed.

*Recommendation:* Always schema-qualify object names in your code.

### The WHERE Clause

In the WHERE clause, you specify a predicate or logical expression to filter the rows returned by the FROM phase.

Example:
```SQL
SELECT orderid, empid, orderdate, freight
FROM Sales.Orders
WHERE custid = 71;
```

Always keep in mind that T-SQL uses **three-valueed predicate logic**, where logical expressions can evaluate to TRUE, FALSE, or UNKNOWN.

### The GROUP BY Clause

The GROUP BY phase allows you arrange the rows returned by the previous logical query processing phase in groups.

If the query involves grouping:
- All phases subsequent to the GROUP BY phase--including HAVING, SELECT, and ORDER BY -- must operate on groups as opposed to operating on individual rows.
- Each group is ultimately represented by a single row in the final result of the query. This implies that all expressions that you specify in clauses that are processed in phases subsequent to the GROUP BY phase are required to guarantee returning a scalar (single value) per group.

Example:
```SQL
SELECT empid, YEAR(orderdate) AS orderyear
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderyear);
```

Elements that do not participate in the GROUP BY list are allowed only as inputs to an aggregate function such as COUNT, SUM, AVG, MIN, or MAX. If you try to refer to an attribute that does not participate in the GROUP BY list and not as an input to an aggregate function in any clause that is processed after the GROUP BY clause, you get an error.

Note that all aggregate functions ignore NULL marks with one exception--COUNT(\*).

Example:
```SQL
SELECT
	empid,
	YEAR(orderdate) AS orderyear,
	SUM(freight) AS totalfreight,
	COUNT(*) AS numorders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);
```

### The HAVING Clause

With the HAVING clause, you can specify a predicate to filter groups as opposed to filtering individual rows, which happens in the WHERE phase.

Note the difference between HAVING and WHERE clause:

| WHERE                           | HAVING                     |
| :-------------                  | :-------------             |
| Processed before GROUP BY       | Processed after GROUP BY   |
| Filter by individual rows       | Filter by groups           |

Example:
```SQL
SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*)
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1;
```
### The SELECT Clause

The SELECT clause is where you specify the attributes (columns) that you want to return in the result table of the query. You can optionally assign your own name to the target attribute by using the AS clause.

Ways to create *alias*:
- <expression\> AS <alias\>
- <expression\> <alias\>
- <alias\> = <expression\>

It is interesting to note that if by mistake you don't specify a comma between two column names in the SELECT list, your code won't fail. Instead, SQL Server will assume that the second name is an alias for the first column name.

Remember that SELECT clause is processed after the FROM, WHERE, GROUP BY, and HAVING clauses. This means that alias assigned to expressions in the SELECT clause do not exist as far as clauses that are processed before the SELECT clause are concerned.

In the relational model, operations on relations are based on relational algebra and result in a relation (a set). In SQL, things are a bit different in the sense that a SELECT query is not guaranteed to return a true set -- namely, unique rows with no guaranteed order. Instead, it returns a multiset or a bag. You can add *DISTINCT* clause to guarantee uniqueness in the result of a SELECT statement.

SQL supports the use of an asterisk (\*) in the SELECT list to request all attributes from the queried tables instead of listing them explicitly.

```SQL
SELECT * FROM Sales.Shippers
```

Such use of an asterisk is a bad programming practice in most cases.

### The ORDER BY Clause

The ORDER BY clause allows you to sort the rows in the output for presentation purposes. In terms of logical query processing, ORDER BY is the very last clause to be processed -- it is the only phase processed after the SELECT clause.

One of the most important points to understand about SQL is that a table has no guaranteed order, because a table is supposed to represent a set, and a set has no order. However, if you specify an ORDER BY clause, the query result cannot qualify as a table, because the order of the rows in the result is guaranteed. A query with an ORDER BY clause results in what standard SQL calls a cursor -- a nonrelational result with order guaranteed among rows.

T-SQL allows you to specify elements in the ORDER BY clause that do not appear in the SELECT clause, meaning that you can sort by something that you don't necessarily want to return in the output.

However, when DISTINCT is specified, you are restricted in the ORDER BY list only to elements that appear in the SELECT list.

### The TOP and OFFSET-FETCH Filters

#### The TOP Filter

The TOP option is proprietary T-SQL feature that allows you to limit the number or percentage of rows that your query returns. It relies on two elements as part of its specification; one is the number or percent of rows to return, and the other is the ordering.

It's also important to note that when TOP is specified, the ORDER BY clause serves a dual purposes. One purpose is to define presentation ordering in the query result. *Another purpose is to define which rows to filter for TOP.*

You can use the TOP option with the PERCENT keyword.

```SQL
SELECT TOP(1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
```

#### OFFSET-FETCH Fitler

By using the OFFSET clause, you can indicate how many rows to skip, and by using the FETCH clause, you can indicate how many rows to filter after the skipped rows.

```SQL
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate, orderid
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;
```

Note that a query that uses OFFSET-FETCH must have an ORDER BY clause. Also, the FETCH clause isn't supported without an OFFSET clause.

| TOP    		 | OFFSET-FETCH        |
| :------------- | :-------------      |
| less flexible  | more flexible       |
| support PERCENT and WITH TIES       | --       |
| not standard   | standard       |

#### A Quick Look at Window Functions

A window function is a function that, for each row in the underlying query, operates on a window(set) of rows and computes a scalar (single) result value. The window of rows is defined by using an OVER clause.

Example: ROW_NUMBER()
```SQL
SELECT orderid, custid, val,
	ROW_NUMBER() OVER(PARTITION BY custid
					  ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;
```

### Predicates and Operators

- IN predicate: check whether a value is equal to at least one of the elements in a set.
```SQL
SELECT a.orderid, a.empid, a.orderdate
FROM Sales.Orders a
WHERE a.orderid IN (10248, 10249, 10250);
```

- BETWEEN predicate: check whether a value is in a specified range, inclusive of the two specified boundary values.
```SQL
SELECT a.orderid, a.empid, a.orderdate
FROM Sales.Orders a
WHERE a.orderid BETWEEN 10300 AND 10310;
```

- LIKE predicate: check whether a character string value meets specified pattern.

```SQL
SELECT a.empid, a.firstname, a.lastname
FROM HR.Employees a
WHERE lastname LIKE N'D%';
```

Notice the use of the letter N to prefix the string 'D%'; it stands for National and is used to denote that a character string is of a Unicode data type (NCHAR or NVARCHAR), as opposed to a regular character data type (CHAR OR VARCHAR).

- Comparison operators:
	- Standard: =, >, <, <>,
	- Non-standard: !=, !>, !<

- Logical expressions: AND, OR, NOT

```SQL
SELECT orderid, empid, orderdate
FROM Sales.Order
WHERE orderdate >= '20080101'
  AND empid IN (1, 3, 5);
```

- Arithmetic operators: +, - , \*, /, %.

- Precedence among operators:
	1. ()
	2. \*, /, %
	3. +(Positive), -(Negative), +(Addition), +(Concatenation), -(Subtraction)
	4. =, >, <, <>
	5. NOT
	6. AND
	7. BETWEEN, IN, LIKE, OR
	8. =(Assignment)


For the sake of other people who need to review or maintain your code and for readability purpose, it's good practice to use paretheses even when they are not required. The same is true for indentation.

```SQL
SELECT a.orderid, a.custid, a.empid, a.orderdate
FROM Sales.Orders a
WHERE
	(custid = 1 AND empid IN (1, 3, 5))
  OR(custid = 85 AND empid IN (2, 4, 6));
```

### CASE Expressions

A CASE expression is a scalar expression that returns a value based on conditional logic. Note that CASE is an expression and not a statement; that is, it doesn't let you control flow of activity or do something based on conditional logic. Instead, the value it returns is based on conditional logic.

**Two forms of CASE expressions**:
- Simple CASE Form:
```SQL
SELECT a.productid, a.productname, a.categoryid,
  CASE a.categoryid
	WHEN 1 THEN 'Beverages'
	WHEN 2 THEN 'Condiments'
	WHEN 3 THEN 'Confections'
	WHEN 4 THEN 'Dairy Products'
	ELSE 'Unknown Category'
   END AS categoryname
FROM Production.Products a;
```

- Searched CASE Form:
```SQL
SELECT a.orderid, a.custid, a.val,
  CASE
   WHEN a.val < 1000.00 THEN 'Less than 1000'
   WHEN a.val BETWEEN 1000.00 and 3000.00 THEN 'BETWEEN 1000 and 3000'
   WHEN a.val > 3000.00 THEN 'More than 3000'
  END AS valuecategory
FROM Sales.OrderValues a;
```

Other abbreviation functions of CASE expressions:
- ISNULL(col, value)
- COALESCE(?)
- IIF(<logical_expr>, <expr1>, <expr2>)
- CHOOSE(<index>, <expr1>, <expr2>, ...)

### NULL Marks
SQL supports the NULL mark to represent missing values and uses three-valued logic.

The correct definition of the treatment SQL has for query filters is "accept TRUE", meaning that both FALSE and UNKNOWN are filtered out. Conversely, the definition of the treatment SQL has for CHECK constraints is "reject FALSE".

If you want to return all rows for which the region attribute is not WA, including those in which the value is missing, you need to include an explicit test for NULL marks.
```SQL
SELECT a.custid, a.country, a.region, a.city
FROM Sales.Customers AS a
WHERE region <> N'WA'
   OR region IS NULL;
```

Keeping in mind the inconsistent treatment SQL has for UNKNOWN and NULL marks and the potential for logical errors, you should explicitly think of NULL marks and three-valued logic in every query you write.

### All-at-Once Operations

SQL supports a concept called all-at-once operations, which means that all expressions that appear in the same logical query processing phase are evaluated logically at the same point in time.

Because of the all-at-once operations concepts in standard SQL, SQL Server is free to process the expressions in the WHERE clause in any order. SQL Server usually make decisions like this based on cost estimations.

For example, the expressions in WHERE clause below will fail because of all-at-once operations--all expressions will be evaluated at the same time:
```SQL
-- Invalid expressions in WHERE
SELECT col1, col2
FROM dbo.T1
WHERE col1 <> 0 AND col2/col1 > 2

-- Use CASE to guarantee processing order
SELECT col1, col2
FROM dbo.T1
WHERE
	CASE
		WHEN col1 = 0 THEN 'no'
		WHEN col2/col1 > 2 THEN 'yes'
		ELSE 'no'
	END
```

## Working with Character Data

### Data Types

### Collation

### Operators and Functions
#### String Concatenation (Plus Sign [+] Operator and CONCAT Function)

#### The SUBSTRING Function

#### The LEN and DATALENGTH Functions

#### The CHARINDEX Function

#### The PATINDEX Function

#### The REPLACE Function

#### The REPLICATE Function

#### The STUFF Function

#### The UPPER and LOWER Functions  

#### The RTRIM and LTRIM Functions

#### The FORMAT Function

### The LIKE Predicate
#### The % (Percent) Wildcard
#### The _ (Underscore) Wildcard
#### The [List of Characters] Wildcard
#### The [Character-Character] Wildcard
#### The [^Character List or Range] Wildcard
#### The ESCAPE Character

## Working with Date and Time Data

### Date and Time Data Types
|Data Type |Storage(bytes) |Date Range |Accuracy |Recommended Entry Format |
| :------------- | :------------- |:------------- |:------------- |:------------- |
|DATETIME      |8 |1753-01-01 ~ 9999-12-31 |3 1/3 millis|20090212 12:30:15.123|
|SMALLDATETIME |4 |1900-01-01 ~ 2079-06-06 |1 min       |20090212 12:30 |
|DATE          |4 |1900-01-01 ~ 2079-06-06 |1 min       |20090212 12:30 |
|TIME          |4 |1900-01-01 ~ 2079-06-06 |1 min       |20090212 12:30 |
|DATETIME2     |4 |1900-01-01 ~ 2079-06-06 |1 min       |20090212 12:30 |
|DATETIMEOFFSET|4 |1900-01-01 ~ 2079-06-06 |1 min       |20090212 12:30 |

### Literals
SQL Server doesn't provide the means to express a date and time literal; instead, it allows you to specify a literal of a differnt type that can be converted--explicity or implicitly--to a date and time data type.

```SQL
-- Explicit convertion
SELECT * FROM Sales.Orders
WHERE orderdate = CAST('20070212' AS DATETIME)

-- Implicit convertion
SELECT * FROM Sales.Orders
WHERE orderdate = '20070212'
```
In implicity convetion, SQL Server recognizes the literal '20070212' as a character string literal not as a date and time literal, but because the expresion involves operands of two different types, one operand needs to be implicitly converted to the other's type, which is based on *data type precedence*.

Note that some character string formats of date and time literals are *language dependent*. Therefore, it is strongly recommended that you phrase your literals in a language-neutral manner.
```SQL
SET LANGUAGE British;
SELECT CAST('02/12/2007' AS DATETIME); -- language dependent
SELECT CAST('20070212' AS DATETIME);   -- language neutral

SET LANGUAGE us_english;
SELECT CAST('02/12/2007' AS DATETIME);
SELECT CAST('20070212' AS DATETIME);
```

If you insist on using a language-dependent format to express literals, there are 2 options available to you.
- COVERT() funtion: convert to requested data type with specified style represeted by a number.
```SQL
SELECT CONVERT(DATETIME, '02/12/2007', 101); -- DATETIME + 101: mm/dd/yyyy
SELECT CONVERT(DATETIME, '02/12/2007', 103); -- DATETIME + 103: dd/mm/yyyy
```
- PARSE() function: parse as requested data type  with specified culture.
```SQL
SELECT PARSE('02/12/2007' AS DATETIME USING 'en-US');
SELECT PARSE('02/12/2007' AS DATETIME USING 'en-GB');
```

### Working with Date and Time Separately
SQL Server 2008 introduced separate DATE and TIME data types, but in previous versions there is no separation between the 2 components. If you want to work with DATE and TIME separately, you can "zero" the irrelevant part:
- store time part as midnight(00:00:00.0000)
- store date part as base date(1900-01-01)

Or, you can use CHECK constraint to ensure that only midnight is used as the time part/ only base date is used as the date part.

### Filtering Date Ranges
When you need to filter a range of dates, such as a whole year or a whole month ,it seems natural to use functions such as YEAR and MONTH in the where predicate:
```SQL
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE YEAR(orderdate) = 2007;
```
However, you should be aware that in most cases, when you apply manipulation on the filtered column, SQL Server cannot use an index in an efficient manner. To have the potential to use an index efficiently, you need to revise the predicate so that their is no manipulation on the filtered columne, like this:
```SQL
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20070101' AND orderdate < '20080101'
```

### Date and Time Functions
#### Current Date and Time

| Function             | Return Type    | Description                            |
| :-------------       | :------------- | :-------------                         |
| GETDATE              | DATETIME       | Current date and time                  |
| CURRENT_TIMESTAMP    | DATETIME       | Same as GETDATE but ANSI SQL-compliant |
| GETUTCDATE           | DATETIME       | Current date and time in UTC           |
| SYSDATETIME          | DATETIME2      | Current date and time                  |
| SYSUTCDATETIME       | DATETIME2      | Current date and time in UTC           |
| SYSUTCDATETIMEOFFSET | DATETIMEOFFSET | Current date time including time zone  |

```SQL
SELECT
	GETDATE() AS [GETDATE],
	CURRENT_TIMESTAMP AS [CURRENT_TIMESTAMP],
	GETUTCDATE() AS [GETUTCDATE],
	SYSDATETIME() AS [SYSDATETIME],
	SYSUTCDATETIME() AS [SYSUTCDATETIME],
	SYSDATETIMEOFFSET() AS [SYSDATETIMEOFFSET];
```

As you notice, none of the functions return only the current date or time. However, you get those easily by converting CURRENT_TIMESTAMP or SYSDATETIME to DATE or TIME like this:

```SQL
SELECT
	CAST(SYSDATETIME() AS DATE) AS [current_date],
	CAST(SYSDATETIME() AS TIME) AS [current_time];
```
#### The CAST, CONVERT, and PARSE Functions and Their TRY_Counterparts
These 3 functions are used to convert a input value to some target data type. If the conversion fail, they fails, while their TRY_Counterparts return NULL.
**Syntax**
- CAST(value AS datatype)
- CONVERT(datatype, value, [,style_number])
- PARSE(value AS datatype [USING culture])

Note that CAST is ANSI and CONVERT and PARSE aren't.

```SQL
SELECT CAST('20090212' AS DATE);
SELECT CAST(CURRENT_TIMESTAMP AS DATE); -- extract only DATE part
SELECT CAST(CURRENT_TIMESTAMP AS TIME); -- extract only TIME part
-- If you want to work on only date or time, you can "zero" the irrelevant part.
SELECT CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112);
SELECT CAST(CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112) AS DATETIME);
SELECT CONVERT(CHAR(12), CURRENT_TIMESTAMP, 114);
SELECT CAST(CONVERT(CHAR(12), CURRENT_TIMESTAMP, 114) AS DATETIME);
```

#### The SWITCHOFFSET Function
The SWITCHOFFSET function adjusts an input DATETIMEOFFSET value to a specified time zone.
**Syntax**
SWITCHOFFSET(datetimeoffset, timezone)
```SQL
SELECT SYSDATETIMEOFFSET();
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '-05:00');
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00'); -- UTC time
```

#### The TODATETIMEOFFSET Function
The TODATETIMEOFFSET function sets a non-offset-aware date and time value to a offset-aware value.
```SQL
SELECT CAST('20090212' AS DATETIME);
SELECT CAST('20090212' AS DATETIMEOFFSET);
SELECT TODATETIMEOFFSET('20090212', '+08:00');
```
#### DATEADD Function
**Syntax**
DATEADD(part, n, dt_val)
```SQL
SELECT DATEADD(year, 1, '20090212');
```
#### DATEDIFF Function
**Syntax**
DATEDIFF(part, dt_val1, dt_val2)
```SQL
SELECT DATEDIFF(day, '20080212', '20090212');
---- Set the time component of CURRENT_TIMESTAMP to midnight for versions prior to SQL Server 2008
SELECT CURRENT_TIMESTAMP;
SELECT DATEDIFF(day, '20010101', CURRENT_TIMESTAMP);
SELECT DATEADD(day,
			   DATEDIFF(day, '20010101', CURRENT_TIMESTAMP),
			   '20010101'); -- treat '20010101' as anchor date
---- Get the first day of month using DATEADD and DATEDIFF
SELECT DATEDIFF(month, '20010101', CURRENT_TIMESTAMP);
SELECT DATEADD(month,
			   DATEDIFF(month, '20010101', CURRENT_TIMESTAMP),
			   '20010101'); -- set anchor date as the first day of month
---- Get the last day of month
SELECT DATEADD(month,
			   DATEDIFF(month, '19991231', CURRENT_TIMESTAMP),
			   '19991231'); -- set anchor date as the last day of month
```
#### Other Date and Time Functions
```SQL
---- DATEPART(part, dt_val) Function
SELECT DATEPART(month, '20090212');
---- YEAR, MONTH, and DAY Functions: abbreviateions for the DATEPART Function
SELECT
	YEAR('20090212') AS theyear,
	MONTH('20090212') AS themonth,
	DAY('20090212') AS theday;
---- DATENAME(part, dt_val) Function -- language dependent
SELECT DATENAME(month, '20090212');
---- ISDATE(string) Function
SELECT ISDATE('20090212'); -- is date
SELECT ISDATE('20090230'); -- not a date
---- FROMPARTS Functions
SELECT
	DATEFROMPARTS(2012, 2, 12),
	DATETIME2FROMPARTS(2012, 2, 12, 13, 30, 5, 1, 7)
------ DATETIMEFROMPARTS(y, m, d, h, m, s, milliseconds)
------ DATETIMEOFFSETFROMPARTS(y, m, d, h, m, s, fractions, hour_offset, minute_offset, precision)
------ SMALLDATETIMEFROMPARTS(y, m, d, h, m)
------ TIMEFROMPARTS(h, m, s, fractions, precision)

---- EOMONTH(dt_vl, [,months_to_add] Function: return end of the month
SELECT EOMONTH(SYSDATETIME());
SELECT EOMONTH(SYSDATETIME(), -2);

```
## Querying Metadata
SQL Server provides tools for getting information about the metadata of objects. Those tools include:
	- Catalog Views
	- Information Schema Views
	- System Stored procedures and functions
### Catalog Views
Catalog views provide detailed information about objects in the database.
`sys.tables`, `sys.columns`

### Information Schema Views
An information schema view is a set of views that resides in a schema called INFORMATION_SCHEMA and provides metadata information in a standard manner.
`INFORMATION_SCHEMA.TABLES`,`INFORMATION_SCHEMA.COLUMNS`

### System Stored Procedures and Functions
