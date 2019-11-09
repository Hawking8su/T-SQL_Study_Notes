# T-SQL Fundamentals
## Chapter 9 Transactions and Concurrency
### Transactions 
A Transaction is a unit of work that might include multiple activities that query and modify data and that can also change data definition.
	- By default, Sqlserver treats each individual statement as a transaction; in other words, by default, sqlserver automatically commits the transaction at the end of each individual statement.

```sql
BEGIN TRAN
	INSERT INTO dbo.T1(keycol, col1, col2) VALUES(4, 101, 'C');
	INSERT INTO dbo.T1(keycol, col1, col2) VALUES(4, 101, 'X');
COMMIT TRAN  --or ROLLBACK TRAN if you don't want to confirm it 
```
Transaction have 4 properties:
	- Atomicity: a tran is an atomic unit of work. Either all changes in the tran take place or none do. 
	- Consistency: refers to the state of the data that the RDBMS gives you access to as concurrent transactions modify and query it.
	- Isolation: is a mechanism used to control access to data and ensure that transactions access data only if the data is in the level of consistency that those transactions expect.
	- Durability: data changes are always written to the database's transaction log on disk before they are written to the data portion of the database on disk. After the commit instruction is recorded in the transaction log on disk, the transaction is considered durable even if the change hasn't yet made to the data portion on disk.
```SQL
-- USE CASE: insert data in two strong related tables
-- Start a new transaction
BEGIN TRAN;

  -- Declare a variable
  DECLARE @neworderid AS INT;

  -- Insert a new order into the Sales.Orders table
  INSERT INTO Sales.Orders
      (custid, empid, orderdate, requireddate, shippeddate, 
       shipperid, freight, shipname, shipaddress, shipcity,
       shippostalcode, shipcountry)
    VALUES
      (85, 5, '20160212', '20160301', '20160216',
       3, 32.38, N'Ship to 85-B', N'6789 rue de l''Abbaye', N'Reims',
       N'10345', N'France');

  -- Save the new order ID in a variable
  SET @neworderid = SCOPE_IDENTITY();

  -- Return the new order ID
  SELECT @neworderid AS neworderid;

  -- Insert order lines for new order into Sales.OrderDetails
  INSERT INTO Sales.OrderDetails(orderid, productid, unitprice, qty, discount)
    VALUES(@neworderid, 11, 14.00, 12, 0.000),
          (@neworderid, 42, 9.80, 10, 0.000),
          (@neworderid, 72, 34.80, 5, 0.000);

-- Commit the transaction
COMMIT TRAN;
```
### Locks and Blocking
Locks are control resources obtained by a transaction to guard data sources, preventing conflicting or incompatile access by other transactions.
	- Exclusive lock mode: modify data; if granted not compatible with either exclusive or shared lock requrests
	- Shared lock mode: read data; if granted not compatible with exclusive lock requests
	- Troubleshooting Blocking: when one tran holds a lock on a data resource and another tran requests an incompatible lock on the same resource, the request is blocked and the requester enters a wait state. 
```sql
--Connection 1
USE TSQLV4
GO
BEGIN TRAN
	UPDATE Production.Products SET unitprice += 1.00
	WHERE productid=2

--Connection 2(blocked)
SELECT * FROM Production.Products
WHERE productid=2

--Connection 3
-- Find the session that caused the block
SELECT *
FROM sys.dm_tran_locks
-- resource_type: DB, OBJECT, PATE, KEY
-- resource_description: if same, the refer to the same resource
-- request_mode: X--exclusive, S--shared
-- request_status: GRANT OR WAIT
-- request_session_id

-- See the command that caused the blocking
SELECT session_id, ST.text 
FROM sys.dm_exec_connections
CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS ST
WHERE session_id in (54,55)

-- See detailed info about sessions
SELECT * FROM sys.dm_exec_sessions
WHERE session_id in (54,55)

-- See the blocked session
SELECT * FROM sys.dm_exec_requests 
where blocking_session_id>0

KILL 55 -- kill the blocker session 
```

### Isolation Levels
Isolation levels determine the behavior of concurrent users who read or write data. Because a writer require an exclusive lock, you cannot control the way it behave in terms of the locks that they acquire and the duration of the locks. But you can control the way readers behave. 

Sqlserver supports four traditional isolation levels that are based on pessimistic concurrency control:
	- READ UNCOMMITTED: reader doesn't ask for a shared lock, so reader can read uncommitted changes.
	- READ COMMITTED(default): reader do ask for a share lock, so reader can only read committed changes. 
	- REPEATABLE READ: ...
	- SERIALIZABLE: ...
```SQL
--Connection 2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT * FROM Production.Products
WHERE productid=2
```

### Deadlocks
A deadlock is a situation in which two or more processes block each other.
	- Sqlserver detects the deadlock and intervenes by ternminating one of the transactions. Unless otherwise specified, Sqlserver chooses to terminate the transaction that did the least work, because it is cheapest to roll that transaction's work back.
```sql
-- connection 1
-- step 1
BEGIN TRAN
	UPDATE Production.Products SET unitprice += 1.00
	WHERE productid=2
	-- step3
	select orderid, productid, unitprice
	from Sales.OrderDetails 
	WHERE productid = 2
COMMIT TRAN;
-- connection 2
-- step 2
BEGIN TRAN
	UPDATE Sales.OrderDetails SET unitprice += 1.00
	WHERE productid = 2
	-- step 4
	SELECT productid, unitprice
	FROM Production.Products
	WHERE productid=2
COMMIT TRAN;

```
	- A few practice to mitigate deadlock occurance:
		- Try to keep transactions as short as possible, taking activities out of the tran that aren't logically supposed to be part of the same unit of work.
		- A deadlock happens when transactions access resources in inverse order.
		- Good index design can help mitigate the occurance of deadlock.
