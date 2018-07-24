# T-SQL Fundamentals
## Chapter 8 Data Modification
DML includes statements: SELECT, INSERT, UPDATE, DELETE, TRUNCATE, and MERGE.

### Inserting Data

#### The INSERT VALUES Statement

Specifying the target column names right after the table name is optional, but by doing so, you control the value-column associations instead of relying on the order in which the columns appeared when the table was defined.

How SQL Server insert values:
  - if a value is specified, use specified value.
  - if no value provided, check for default value.
  - if no default value, insert NULL.
  - if NULL is not allowed, returns error.

```SQL
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
  VALUES(10001, '20090212', 3, 'A');

INSERT INTO dbo.Orders(orderid, empid, custid)
	VALUES(10002, 5, 'B');
---- enhanced VALUES clause
INSERT INTO dbo.Orders
		(orderid, orderdate, empid, custid)
	VALUES
		(10003, '20090213', 4, 'B'),
		(10004, '20090214', 1, 'A');
---- Note: this statement is processed as an atomic operation.
```

#### The INSERT SELECT Statement
```SQL
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	SELECT orderid, orderdate, empid, custid
	FROM Sales.Orders
	WHERE shipcountry = 'UK';
```
This is an atomic operation.

#### The INSERT EXEC Statement
Use the INSERT EXEC statement to insert a result set returned from a stored procedure or a dynamic SQL batch into a target table.
```SQL
---- create procedure called Sales.usp_getorders, returning
---- orders that were shipped to a specified input country.
IF OBJECT_ID('Sales.usp_getorders') IS NOT NULL
	DROP PROC Sales.usp_getorders;
GO

CREATE PROC Sales.usp_getorders
	@country AS NVARCHAR(40)
AS
	SELECT orderid, orderdate, empid, custid
	FROM Sales.Orders
	WHERE shipcountry = @country;
GO
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	EXEC Sales.usp_getorders @country = 'France';

```
#### The SELECT INTO Statement
nonstandard T-SQL statement. You don't need to specify table structure before inserting values. The target table's structure and data based on the source table. There are 4 things that the statement does not copy from the source: constraints, indexes, triggers, and permissions.
```SQL
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
SELECT orderid, orderdate, empid, custid
INTO dbo.Orders
FROM Sales.Orders

```
Use SELECT INTO statement with set operations:
```SQL
IF OBJECT_ID('dbo.Locations', 'U') IS NOT NULL DROP TABLE dbo.Locations;
SELECT country, region, city
INTO dbo.Locations
FROM Sales.Customers

EXCEPT

SELECT country, region, city
FROM HR.Employees

```

#### The BULK INSERT Statement
Use the Bulk INSERT statement to insert into an existing table data originating from a file.
```SQL
BULK INSERT dbo.Orders FROM 'c:\temp\orders.txt'
	WITH
		(
			DATAFILETYPE = 'char',
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n'
		);
SELECT * FROM dbo.Orders;
```

#### The Identity Property and the Sequence Object

##### Identity

##### Sequence

### Deleting Data
#### The DELETE Statement
```SQL
DELETE FROM dbo.Orders
WHERE orderdate < '20150101';
```
#### The TRUNCATE Statement
```SQL
TRUNCATE TABLE dbo.T1;
```
| aspects  | DELETE     | TRUNCATE   |
| :------- | :--------- |:---------- |
| filter   | optional   | no         |
| log      | fully      | minimally  |
| identity | deleted    | set back to seed value  |

Note:
  - TRUNCATE is minimally logged (as opposed to not being logged at all), meaning that in case of a ROLLBACK, SQL Server can undo the trunction.
  - TRUNCATE is not allowed when the target table is referenced by a foreign key constraint, even if the referencing table is empty and even if the foreign key is disabled. The only way to allow a TRUNCATE statement is to drop all foreign keys referencing the table.
  - To prevent unintentional deletion or truncation, you can protect a production table by simply creating a dummy table with a foreign key pointing to the production table.

#### DELETE Based on a Join
Nonstandard.
  - JOIN itself serves a filtering purpose because it has a filter based on the ON predicate.
  - JOIN also gives you access to related rows from another table in the WHERE clause.
  - Meaning that you can delete rows from one table based on a filter against another table.
```SQL
---- delete orders placed by customers from the US.
DELETE FROM O
FROM dbo.Orders AS O
	JOIN dbo.Customers AS C
		ON O.custid = C.custid
WHERE C.country = N'USA';
---- standard SQL
DELETE FROM dbo.Orders
WHERE EXISTS
	(SELECT *
	FROM dbo.Orders AS O
		JOIN dbo.Customers AS C
			ON O.custid = C.custid
	WHERE C.country = N'USA');
```

NOTE:
  - The two FROM clause might be confusing. But when you develop the code, develop it as if it were a SELECT statement with a join.
  - It is usually recommended to stick to the standard as much as possible unless you have a very compelling reason to do otherwise.

### Updating Data
T-SQL supports a standard UPDATE statement that allows you to update rows in a table. Key clauses: UPDATE, SET, WHERE.
#### The UPDATE statement
```SQL
UPDATE dbo.OrderDetails
	SET discount += 0.05
WHERE productid = 51
```
 All-at-once operations are an important aspect of SQL. Remember the concept that says that all expressions in the same logical phase are evaluated logically at the same point in time.
 ```SQL
 -- This might not do what you want:
 -- if col1=100, after updates, col1=110, col2=110(not 120)
 UPDATE dbo.T1
  SET col1 = col1 + 10, col2 = col1 + 10;

-- Because of all-at-once operation, it's simple to swap 2 values.
-- Unlike in most other programming language, you don't need a temporary variable.
UPDATE dbo.T1
  SET col1 = col2, col2 = col1;
 ```
#### UPDATE Based on a Join
Nonstandard.
  - First write the Join query with SELECT.
  - Then substitute SELECT with UPDATE...SET...

```SQL
---- UPDATE based on JOIN
UPDATE OD
	SET discount += 0.05
FROM dbo.OrderDetails AS OD
	JOIN dbo.Orders AS O
		ON OD.orderid = O.orderid
WHERE O.custid = 1;
---- standard SQL: using subqueries
UPDATE dbo.OrderDetails
	SET discount += 0.05
WHERE EXISTS
	(SELECT * FROM dbo.Orders AS O
	 WHERE O.orderid = OrderDetails.orderid -- how to understand this part?
		 AND O.custid = 1);
```
NOTE--**Understanding EXISTS** Predicate:
WHERE EXISTS is a filter that returns TRUE or FALSE based on whether the SELECT subquery returns any values. The logical processing phase is:
  1. The current orderid in the OrderDetails table is 1 =>
  2. SELECT subquery returns values =>
  3. WHERE EXISTS returns TRUE =>
  4. UPDATE value =>
  5. proceed to the next orderid in the OrderDetails table ...

In addition to filtering, the join also gives you access to attributes from other tables that you can use in the column assignment in the SET clause.

```SQL
---- UPDATE with JOIN using attributes from another table
UPDATE T1
	SET col1 = T2.col1,
		  col2 = T2.col2,
			col3 = T2.col3
FROM dbo.T1 JOIN dbo.T2
	ON T1.keycol = T2.keycol
WHERE T2.col4 = 'ABC';
---- it will be lengthy and convoluted to rewrite the code above
---- using subqueries.
```

#### Assignment UPDATE
T-SQL supports a proprietary UPDATE syntax that both updates data in a table and assigns values to variables at the same time. One of the common cases for which you can use this syntax is in maintaining a custom sequence/autonumbering mechanism when the identity column property and the sequence object don't work for you.
```SQL
DECLARE @nextval AS INT;
UPDATE dbo.Sequences
	SET @nextval = val += 1 -- first val+=1, then @nextval = val;
WHERE id = 'SEQ1';
SELECT @nextval;
```


### Merging Data
MERGE allows you to modify data, applying different actions (INSERT, UPDATE, and DELETE) based on conditional logic. The benefit of using MERGE over the alternatives is that is allows you to express the request with less code and run it more efficiently because it requires fewer access to the tables involved.
```SQL
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
GO
CREATE TABLE dbo.Customers
(
	custid INT NOT NULL,
	companyname VARCHAR(25) NOT NULL,
	phone VARCHAR(20) NOT NULL,
	address VARCHAR(50) NOT NULL,
	CONSTRAINT PK_Customers PRIMARY KEY(custid)
);
INSERT INTO dbo.Customers(custid, companyname, phone, address)
VALUES
	(1, 'cust 1', '(111) 111-1111', 'address 1'),
	(2, 'cust 2', '(222) 222-2222', 'address 2'),
	(3, 'cust 3', '(333) 333-3333', 'address 3'),
	(4, 'cust 4', '(444) 444-4444', 'address 4'),
	(5, 'cust 5', '(555) 555-5555', 'address 5');
IF OBJECT_ID('dbo.CustomersStage', 'U') IS NOT NULL DROP TABLE dbo.CustomersStage;
GO
CREATE TABLE dbo.CustomersStage
(
	custid INT NOT NULL,
	companyname VARCHAR(25) NOT NULL,
	phone VARCHAR(20) NOT NULL,
	address VARCHAR(50) NOT NULL,
	CONSTRAINT PK_CustomersStage PRIMARY KEY(custid)
);
INSERT INTO dbo.CustomersStage(custid, companyname, phone, address)
VALUES
	(2, 'AAAAA', '(222) 222-2222', 'address 2'),
	(3, 'cust 3', '(333) 333-3333', 'address 3'),
	(5, 'BBBBB', 'CCCCC', 'DDDDD'),
	(6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
	(7, 'cust 7 (new)', '(777) 777-7777', 'address 7');

SELECT * FROM dbo.Customers;
SELECT * FROM dbo.CustomersStage;
-- Merge the contents of the CustomerStage table (the source)
-- to the Customers table (the target). More specifically, add
-- customers that do not exist, and update attributes of customers
-- who already exists.												
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	 ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address);
```
Key points:
  - It is mandatory to terminate the MERGE statement with a semicolon.
  - three cases:
    - WHEN MATCHED THEN: TGT.keycol = SRC.keycol => UPDATE TGT SET...
    - WHEN NOT MATCHED THEN: TGT.keycol <> SRC.keycol -- exists in SRC but not in TGT => INSERT INTO TGT
    - WHEN NOT MATCHED BY SOURCE: TGT.keycol <> SRC.keycol -- exists in TGT but not in SRC => DELETE FROM TGT  

```SQL
---- WHEN NOT MATCHED BY SOURCE THEN
MERGE dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
-- check if identical before update
WHEN MATCHED AND
  (		TGT.companyname <> SRC.companyname,
   OR TGT.phone <> SRC.phone,
   OR TGT.address <> SRC.address) THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;
```  

### Modifying Data Through Table Expressions
A table expression doesn't really contain data -- it's a reflection of underlying data in base tables. With this in mind, think of a modification against a table expression as modifying the data in the underlying tables through the table expression.

A few logical restrictions:
- If joins, you are only allowed to affect one of the sides of the join not both in the same modification statement.
- You cannot update a column that is a result of a calculation.
- INSERT statements must specify values for any columns in the underlying table that do not have implicit values.
  Note: A column can get a value implicitly if:
  - it allows NULL marks
  - has default value
  - has an identity property
  - or is typed as ROWVERSION

One reason to modify data through table expressions is for better debugging and troubleshooting -- You can SELECT the subset and then modify conveniently.
```SQL
WITH C AS
(
	SELECT custid, OD.orderid, productid,
		discount, discount + 0.05 AS newdiscount
	FROM dbo.OrderDetails AS OD
		JOIN dbo.Orders AS O
			ON OD.orderid = O.orderdate
	WHERE O.custid = 1
)
UPDATE C
	SET discount = newdiscount;
```

With some problems, using a table expression is the only option. For example, if you want to control the order of rows in data modification, since ORDER BY is not allowed in DML, you can use an ordered table expression as a solution.
```SQL
---- this returns an error.
UPDATE dbo.T1
	SET col2 = ROW_NUMBER() OVER(ORDER BY col1);
---- work around this problem using CTE.
WITH C AS
(
	SELECT col1, col2, ROW_NUMBER() OVER(ORDER BY col1) AS rownum
	FROM dbo.T1
)
UPDATE C
	SET col2 = rownum;
```
### Modification with TOP and OFFSET-FETCH
Unfortunately, unlike with the SELECT statement, you cannot specify an ORDER BY clause for the TOP option with modification statements. Essentially, whichever rows SQL Server happens to access first will be the rows affected by the modification.

An example for typical usage scenario for modifications with TOP is when you have a large modification, such as a large deletion operation, and you want to split it into multiple smaller chunks.

The new alternative to TOP, OFFSET-FETCH, is considered to be part of the ORDER BY clause in T-SQL, so is not supported in the DML either.

To get around this problem, you can rely on the fact that you can modify data through table expressions.
```SQL
---- without ORDER BY, these queries are problematic
DELETE TOP(50) FROM dbo.Orders;
UPDATE TOP(50) dbo.Orders
	SET freight += 10.00;
---- you can solve this problem using table expressions
WITH C AS
(
	SELECT TOP(50) *
	FROM dbo.Orders
	ORDER BY orderid
)
DELETE FROM C;

WITH C AS
(
	SELECT TOP(50) *
	FROM dbo.Orders
	ORDER BY orderid
)
UPDATE C
	SET freight += 10.00;
```

### The OUTPUT Clause
In some scenarios, being able to get data back from the modified rows can be useful. For example, think about the advantages of requesting an UPDATE statement to not only modify data, but to also return the old and new values of the updated columns.

In the OUTPUT clause, you specify the attributes and expressions that you want to return from the modified rows. What's special is that you need to prefix the attribute names with either the *inserted* or the *deleted* keyword. If you wanto direct the result set to a table, add an INTO clause with the target table name.

#### INSERT with OUTPUT
```SQL
---- Insert and return inserted rows.
INSERT INTO dbo.T1(datacol)
	OUTPUT inserted.keycol, inserted.datacol
		SELECT lastname
		FROM HR.Employees
		WHERE country = N'USA';
```
You can direct the result set into a table -- either a real table, a temporary table, or a table variable.
```SQL
---- direct result to a table variable
DECLARE @NewRows TABLE(keycol INT, datacol NVARCHAR(40));
INSERT INTO dbo.T1(datacol)
	OUTPUT inserted.keycol, inserted.datacol
	INTO @NewRows
		SELECT lastname
		FROM HR.Employees
		WHERE country = N'USA';
SELECT * FROM @NewRows;
```

#### DELETE with OUTPUT
```SQL
DELETE FROM dbo.Orders
	OUTPUT
		deleted.orderid,
		deleted.orderdate,
		deleted.empid,
		deleted.custid
WHERE orderdate < '20160101';
```
If you want to achive the rows that are deleted, simply add an INTO clause and specify the archive table name as the target.

#### UPDATE with OUTPUT
You can refer to both the image of the modified row before the change (prefix with *deleted*) and the image after the change (prefix with *inserted*).
```SQL
UPDATE dbo.OrderDetails
	SET discount += 0.05
OUTPUT
	inserted.productid,
	deleted.discount AS olddiscount,
	inserted.discount AS newdiscount
WHERE productid = 51;
```

#### MERGE with OUTPUT
Remember that a single MERGE statement can invoke multiple different DML actions based on conditional logic. To identify which DML action produced the output row, you can invoke a function called *$action* in the OUTPUT clause, which will return a string representing the action (INSERT, UPDATE, or DELETE).
```SQL
-- note: there are 2 cases/actions involved:
-- WHEN MATECHED THEN: UPDATE and WHEN NOT MATCHED THEN: INSERT
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
OUTPUT
	$action AS theaction, inserted.custid,
	deleted.companyname AS oldcompanyname,
	inserted.companyname AS newcompanyname,
	deleted.phone AS oldphone,
	inserted.phone AS newphone,
	deleted.address AS oldaddress,
	inserted.address AS newaddress;
```

#### Composable DML
The OUTPUT clause returns an output row for every modified row. If you need to direct only a subset of the modified rows, you can use a feature supported by SQL Server called composable DML. -- You can write an INSERT SELECT statement that queries the derived table of DML.

Remember about logical query processing and table expressions--the multiset output of one query can be used as input to subsequent SQL statements.
```SQL
INSERT INTO dbo.ProductsAudit(productid, colname, oldval, newval)
	SELECT productid, N'unitprice', oldval, newval
	FROM (UPDATE dbo.Products
					SET unitprice *= 1.15
				OUTPUT
					inserted.productid,
					deleted.unitprice AS oldval,
					inserted.unitprice AS newval
			  WHERE supplierid = 1) AS D
	WHERE oldval < 20.0 AND newval >= 20.0;

SELECT * FROM dbo.ProductsAudit;
```
