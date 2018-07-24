# T-SQL Fundamentals
## Chapter 6 Set Operators

Set operators are operators that are applied between two input sets, or multisets, that results from two input queries. Remember, a multisets is not a true set, because it can contain duplicates. Multisets refering to the intermediate results from two input queries that might contain duplicates.

T-SQL supports 3 set operators: **UNION, INTERSECT, EXCEPT**.

General form of a query with a set operator:
```
Input Query1
<set_operator>
Input Query2
[ORDER BY ...]
```
A set operator compares complete rows between the result sets of the two input queries involved. Interestingly, a set operator considers two NULLs as equal.

Because by definition a set operator is applied to two sets and a set has no guaranteed order, the two queries involved cannot have ORDER BY clauses. Remember that a query with an ORDER BY clause guarantees presentation order and therefore does not return a set -- it returns a cursor.

The two queries involved in a set operator must produce results with the same number of columns, and corresponding columns must have *compatible data types*.

Standard SQL supports two "flavors" of each operator -- DISTINCT(default) and ALL.

### The UNION Operator
In set theory, the union of two sets is the set containing all elements of both A and B.

#### The UNION ALL Multiset Operator
Query1 (m rows) UNION ALL Query2 (n rows) => m + n rows (without comparing rows and eliminating duplicates => returns a multiset).
```SQL
SELECT country, region, city FROM HR.Employees
UNION ALL
SELECT country, region, city FROM Sales.Customers;
```
#### The UNION Distinct Set Operator
Query1 (m rows) UNION ALL Query2 (n rows) => m + n - duplicate rows (returns a set)
```SQL
SELECT country, region, city FROM HR.Employees
UNION
SELECT country, region, city FROM Sales.Customers;
```

### The INTERSECT Operator
In set theory, the intersection of two sets is the set of all elements that belong to A and also belong to B.

#### The INTERSECT Distinct Set Operator
Logical operation steps:
1. eliminate duplicate rows from the two input multisets
2. then returns only rows that appear in both sets.

```SQL
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;
```
Note: when comparing rows, a set operator considers two NULL marks as equal. If this is not what you want, you can use inner join and EXCEPT instead.

#### The INTERSECT ALL Multiset Operator
If there are x rows of R in the first input and y rows of R in the second inputs, INTERSET ALL should return min(x, y) rows of R in the result-- because at the logical level, min(x, y) occurences can be intersected. In other words, it does not only care about the existence of a row in both sides -- it also cares about the number of occurences of the row in each side.

T-SQL doesn't provide INTERSECT ALL operator, instead you can use INTERSECT and ROW_NUMBER function to achieve the same result.
```SQL
-- INTERSECT + ROW_NUMBER = INTERSECT ALl
-- Note: ROW_NUMBER() must have ORDER BY clause.
-- Using ORDER BY (SELECT <constant>) is one of several ways to tell SQL
-- that order doesn't matter.  
SELECT ROW_NUMBER()
	OVER(PARTITION BY country, region, city
			 ORDER BY (SELECT 0)) AS rowsum,
	country, region, city
FROM HR.Employees
INTERSECT
SELECT ROW_NUMBER()
	OVER(PARTITION BY country, region, city
			 ORDER BY (SELECT 0)) AS rowsum,
	country, region, city
FROM Sales.Customers;

-- To not return row numbers: CTEs + INTERSET ALL
WITH INTERSECT_ALL AS
(
	SELECT ROW_NUMBER()
		OVER(PARTITION BY country, region, city
				 ORDER BY (SELECT 0)) AS rowsum,
		country, region, city
	FROM HR.Employees
	INTERSECT
	SELECT ROW_NUMBER()
		OVER(PARTITION BY country, region, city
				 ORDER BY (SELECT 0)) AS rowsum,
		country, region, city
	FROM Sales.Customers
)
SELECT country, region, city
FROM INTERSECT_ALL;
```

### The EXCEPT Operator
In set theory, the difference of sets A and B (A - B) is the set of elements that belong to A and do not belong to B. The EXCEPT operator returns rows that appear in the first input but not the second.

#### The EXCEPT Distinct Set Operator
Logical steps:
1. eliminate duplicate rows.
2. returns rows that appear in the first set but not the second.

Note: unlike other set operators, EXCEPT is asymmetric.
Alternatives: outer join, NOT EXISTS

#### The EXCEPT ALL Multiset Operator
Provided that a row R appears x timesin the first multiset and y times in the second, and x > y, R will appear x - y times in Query1 EXCEPT ALL Query2.

T-SQL does not provide a built-in EXCEPT ALL operator. Alternative: EXCEPT + ROW_NUMBER => EXCEPT ALL.
```SQL
WITH EXCEPT_ALL AS
(
	SELECT ROW_NUMBER()
		OVER(PARTITION BY country, region, city
				 ORDER BY (SELECT 0)) AS rowsum,
		country, region, city
	FROM HR.Employees
	EXCEPT
	SELECT ROW_NUMBER()
		OVER(PARTITION BY country, region, city
				 ORDER BY (SELECT 0)) AS rowsum,
		country, region, city
	FROM Sales.Customers
)
SELECT country, region, city
FROM EXCEPT_ALL;
```

### Precedence
INTERSECT operator precedes UNION and EXCEPT, and UNION and EXCEPT are considered equal (evaluated based on order of occurances).
```SQL
---- Return locations that are supplier locations but not (locations
---- that are both employee and customer locations).
SELECT country, region, city FROM Production.Suppliers
EXCEPT
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers
```
To control the order of evaluation of set operators, use parentheses, because they have the highest precedence. Also, it increases the readability, thus reducing the chance for errors.

### Circumventing Unsupported Logical Phases
As of now:
- for individual query: all logical query processing phases is allowd except ORDER BY.
- for result of operator: only ORDER BY clause is allowed.

To circumvent the second restriction, you can define a table expression based on the operator result. For example:
```SQL
SELECT country, COUNT(*) AS numlocations
FROM (SELECT country, region, city FROM HR.Employees
			UNION
			SELECT country, region, city FROM Sales.Customers) AS U
GROUP BY country;
```

To circumvent the first restriction, you can also use table expressions. Recall that an ORDER BY clause is allowed in a query with TOP or OFFSET-FETCH, even when the query is usedto define a table expression. In such a case, the ORDER BY clause serves only as a part of the filtering specification and has no presentation meaning.
```SQL
---- return two most recent orders for thos employee with an
---- employee ID of 3 or 5.
SELECT empid, orderid, orderdate
FROM (SELECT TOP(2) empid, orderid, orderdate
			FROM Sales.Orders
			WHERE empid = 3
			ORDER BY orderdate DESC, orderid DESC) AS D1

UNION ALL

SELECT empid, orderid, orderdate
FROM (SELECT TOP(2) empid, orderid, orderdate
			FROM Sales.Orders
			WHERE empid = 5
			ORDER BY orderdate DESC, orderid DESC) AS D2;
```
