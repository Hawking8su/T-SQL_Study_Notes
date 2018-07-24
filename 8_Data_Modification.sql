-- T-SQL Fundamentals
-- Chapter 8 Data Modification 
USE TSQLV4;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
CREATE TABLE dbo.Orders
(
	orderid INT	NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
	orderdate DATE NOT NULL CONSTRAINT DFT_orderdate DEFAULT(SYSDATETIME()),
	empid INT NOT NULL,
	custid VARCHAR(10) NOT NULL
)

-- 1. INSERT 
--- INSERT INTO 
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
SELECT * FROM dbo.Orders;

--- INSERT SELECT 
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	SELECT orderid, orderdate, empid, custid 
	FROM Sales.Orders
	WHERE shipcountry = 'UK';

--- INSERT EXEC
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


--- SELECT INTO
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
SELECT orderid, orderdate, empid, custid
INTO dbo.Orders
FROM Sales.Orders 

IF OBJECT_ID('dbo.Locations', 'U') IS NOT NULL DROP TABLE dbo.Locations;
SELECT country, region, city 
INTO dbo.Locations
FROM Sales.Customers
EXCEPT 
SELECT country, region, city 
FROM HR.Employees

--- BULK INSERT 
BULK INSERT dbo.Orders FROM 'c:\temp\orders.txt'
	WITH 
		(
			DATAFILETYPE = 'char',
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n'
		);
SELECT * FROM dbo.Orders;

-- 2. Deleting Data
USE TSQLV4;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
CREATE TABLE dbo.Customers
(
	custid INT NOT NULL,
	companyname NVARCHAR(40) NOT NULL,
	contactname NVARCHAR(30) NOT NULL,
	contacttitle NVARCHAR(30) NOT NULL,
	address NVARCHAR(60) NOT NULL,
	city NVARCHAR(15) NOT NULL,
	region NVARCHAR(15) NULL,
	postalcode NVARCHAR(10) NULL,
	country NVARCHAR(15) NOT NULL,
	phone NVARCHAR(24) NOT NULL,
	fax NVARCHAR(24) NULL,
	CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	custid INT NULL,
	empid INT NOT NULL,
	orderdate DATETIME NOT NULL,
	requireddate DATETIME NOT NULL,
	shippeddate DATETIME NULL,
	shipperid INT NOT NULL,
	freight MONEY NOT NULL
	CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname NVARCHAR(40) NOT NULL,
	shipaddress NVARCHAR(60) NOT NULL,
	shipcity NVARCHAR(15) NOT NULL,
	shipregion NVARCHAR(15) NULL,
	shippostalcode NVARCHAR(10) NULL,
	shipcountry NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid),
	CONSTRAINT FK_Orders_Customers FOREIGN KEY(custid)
	REFERENCES dbo.Customers(custid)
);
GO
INSERT INTO dbo.Customers SELECT * FROM Sales.Customers;
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
GO
-- DELETE 
DELETE FROM dbo.Orders
WHERE orderdate < '20150101';

-- DELETE Based on a Join
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
	FROM dbo.Customers AS C
	WHERE Orders.custid = C.custid 
		AND C.country = N'USA');
---- clean up 
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;

-- 3.Updating Data 
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	custid INT NULL,
	empid INT NOT NULL,
	orderdate DATETIME NOT NULL,
	requireddate DATETIME NOT NULL,
	shippeddate DATETIME NULL,
	shipperid INT NOT NULL,
	freight MONEY NOT NULL
	CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname NVARCHAR(40) NOT NULL,
	shipaddress NVARCHAR(60) NOT NULL,
	shipcity NVARCHAR(15) NOT NULL,
	shipregion NVARCHAR(15) NULL,
	shippostalcode NVARCHAR(10) NULL,
	shipcountry NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
CREATE TABLE dbo.OrderDetails
(
	orderid INT NOT NULL,
	productid INT NOT NULL,
	unitprice MONEY NOT NULL
	CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
	qty SMALLINT NOT NULL
	CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
	discount NUMERIC(4, 3) NOT NULL
	CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
	CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY(orderid)
	REFERENCES dbo.Orders(orderid),
	CONSTRAINT CHK_discount CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;
GO
---- UPDATE 
UPDATE dbo.OrderDetails
	SET discount += 0.05
WHERE productid = 51

---- UPDATE Based on a Join
UPDATE OD 
	SET discount += 0.05
FROM dbo.OrderDetails AS OD 
	JOIN dbo.Orders AS O 
		ON OD.orderid = O.orderid
WHERE O.custid = 1;

---- standard SQL 
UPDATE dbo.OrderDetails
	SET discount += 0.05
WHERE EXISTS 
	(SELECT * FROM dbo.Orders AS O
	 WHERE O.orderid = OrderDetails.orderid -- how to understand this part?
		 AND O.custid = 1);
---- UPDATE with JOIN with another table
UPDATE T1
	SET col1 = T2.col1,
		  col2 = T2.col2,
			col3 = T2.col3
FROM dbo.T1 JOIN dbo.T2 
	ON T1.keycol = T2.keycol
WHERE T2.col4 = 'ABC';
---- it will be lengthy and convoluted to rewrite the code above using subqueries. 

---- Assignment UPDATE
IF OBJECT_ID('dbo.Sequences', 'U') IS NOT NULL DROP TABLE dbo.Sequences;
CREATE TABLE dbo.Sequences
(
	id VARCHAR(10) NOT NULL
		CONSTRAINT PK_Sequences PRIMARY KEY(id),
	val INT NOT NULL
);
INSERT INTO dbo.Sequences VALUES('SEQ1', 0);

DECLARE @nextval AS INT;
UPDATE dbo.Sequences
	SET @nextval = val += 1 -- first val+=1, then @nextval = val;
WHERE id = 'SEQ1';
SELECT @nextval;

---- clean up 
IF OBJECT_ID('dbo.Sequences', 'U') IS NOT NULL DROP TABLE dbo.Sequences;

-- 4. MEREGE 
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
-- To merge the contents of the CustomerStage table (the source)
-- to the Customers table (the target). More specifically, add
-- customers that do not exist, and update attributes that 
-- already exists.												
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

---- WHEN NOT MATCHED BY SOURCE THEN
MERGE dbo.Customers AS TGT
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
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

-- Modifying Data Through Table Expressions
---- normal UPDATE 
UPDATE OD 
	SET discount += 0.05
FROM dbo.OrderDetails AS OD
	JOIN dbo.Orders AS O
		ON OD.orderid = O.orderid
WHERE O.custid = 1;

---- with Table Expressions
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

---- ORDER BY + Table expression in DML
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1(col1 INT, col2 INT);
GO

INSERT INTO dbo.T1(col1) VALUES(10),(20),(30);

SELECT * FROM dbo.T1;
---- this returns an error.
UPDATE dbo.T1 
	SET col2 = ROW_NUMBER() OVER(ORDER BY col1);

WITH C AS
(
	SELECT col1, col2, ROW_NUMBER() OVER(ORDER BY col1) AS rownum
	FROM dbo.T1
)
UPDATE C 
	SET col2 = rownum;

-- 5. Modification with TOP and OFFSET-FETCH
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	custid INT NULL,
	empid INT NOT NULL,
	orderdate DATETIME NOT NULL,
	requireddate DATETIME NOT NULL,
	shippeddate DATETIME NULL,
	shipperid INT NOT NULL,
	freight MONEY NOT NULL
	CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname NVARCHAR(40) NOT NULL,
	shipaddress NVARCHAR(60) NOT NULL,
	shipcity NVARCHAR(15) NOT NULL,
	shipregion NVARCHAR(15) NULL,
	shippostalcode NVARCHAR(10) NULL,
	shipcountry NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
GO
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;

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
-- 6. The OUTPUT Clause
---- INSERT with OUTPUT
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1
(
	keycol INT NOT NULL IDENTITY(1, 1) CONSTRAINT PK_T1 PRIMARY KEY,
	datacol NVARCHAR(40) NOT NULL
);
---- Insert and return inserted rows.
INSERT INTO dbo.T1(datacol)
	OUTPUT inserted.keycol, inserted.datacol
		SELECT lastname 
		FROM HR.Employees
		WHERE country = N'USA';
---- direct result to a table variable 
DECLARE @NewRows TABLE(keycol INT, datacol NVARCHAR(40));
INSERT INTO dbo.T1(datacol)
	OUTPUT inserted.keycol, inserted.datacol
	INTO @NewRows
		SELECT lastname 
		FROM HR.Employees
		WHERE country = N'USA';
SELECT * FROM @NewRows;

---- DELETE with OUTPUT
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	custid INT NULL,
	empid INT NOT NULL,
	orderdate DATETIME NOT NULL,
	requireddate DATETIME NOT NULL,
	shippeddate DATETIME NULL,
	shipperid INT NOT NULL,
	freight MONEY NOT NULL
	CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname NVARCHAR(40) NOT NULL,
	shipaddress NVARCHAR(60) NOT NULL,
	shipcity NVARCHAR(15) NOT NULL,
	shipregion NVARCHAR(15) NULL,
	shippostalcode NVARCHAR(10) NULL,
	shipcountry NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;

DELETE FROM dbo.Orders
	OUTPUT
		deleted.orderid,
		deleted.orderdate,
		deleted.empid,
		deleted.custid
WHERE orderdate < '20160101';

---- UPDATE with OUTPUT
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
CREATE TABLE dbo.OrderDetails
(
	orderid INT NOT NULL,
	productid INT NOT NULL,
	unitprice MONEY NOT NULL
		CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
	qty SMALLINT NOT NULL
		CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
	discount NUMERIC(4, 3) NOT NULL
		CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
	CONSTRAINT CHK_discount CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

UPDATE dbo.OrderDetails
	SET discount += 0.05
OUTPUT 
	inserted.productid,
	deleted.discount AS olddiscount,
	inserted.discount AS newdiscount
WHERE productid = 51;

---- MERGE with OUTPUT
SELECT * FROM dbo.Customers;
SELECT * FROM dbo.CustomersStage;

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

---- Composable DML
IF OBJECT_ID('dbo.ProductsAudit', 'U') IS NOT NULL DROP TABLE dbo.ProductsAudit;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
CREATE TABLE dbo.Products
(
	productid INT NOT NULL,
	productname NVARCHAR(40) NOT NULL,
	supplierid INT NOT NULL,
	categoryid INT NOT NULL,
	unitprice MONEY NOT NULL
	CONSTRAINT DFT_Products_unitprice DEFAULT(0),
	discontinued BIT NOT NULL
	CONSTRAINT DFT_Products_discontinued DEFAULT(0),
	CONSTRAINT PK_Products PRIMARY KEY(productid),
	CONSTRAINT CHK_Products_unitprice CHECK(unitprice >= 0)
);
INSERT INTO dbo.Products SELECT * FROM Production.Products;
CREATE TABLE dbo.ProductsAudit
(
	LSN INT NOT NULL IDENTITY PRIMARY KEY,
	TS DATETIME NOT NULL DEFAULT(CURRENT_TIMESTAMP),
	productid INT NOT NULL,
	colname SYSNAME NOT NULL,
	oldval SQL_VARIANT NOT NULL,
	newval SQL_VARIANT NOT NULL
);
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
---- clean up
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.ProductsAudit', 'U') IS NOT NULL DROP TABLE dbo.ProductsAudit;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
IF OBJECT_ID('dbo.Sequences', 'U') IS NOT NULL DROP TABLE dbo.Sequences;
IF OBJECT_ID('dbo.CustomersStage', 'U') IS NOT NULL DROP TABLE dbo.CustomersStage;