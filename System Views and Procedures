-- Useful System views and stored procedures in Sqlserver
USE TSQLV4
GO
--Catalog Views
--	provide metadata info in sqlserver manner
select SCHEMA_NAME(schema_id) as table_schema_name, name as table_name
from sys.tables

select name as column_name
	,TYPE_NAME(system_type_id) AS column_type
	,max_length
	,collation_name
	,is_nullable
from sys.columns where object_id=OBJECT_ID('Sales.Orders')

--Information Schema Views
--	provides metadata information in a standard manner.
SELECT * 
FROM INFORMATION_SCHEMA.TABLES 

SELECT TOP 10 * 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='Orders'

--System Stored Procedures and Functions
EXEC sp_tables; --return a list of objects in current db
EXEC sp_help 'Sales.Orders' -- return help info about an object
EXEC sp_helptext 'P2921'; -- return text that about an programmable object
EXEC sp_columns 'Orders', 'Sales'
EXEC sp_helpconstraint 'Sales.Orders'

SELECT OBJECTPROPERTY(OBJECT_ID('Sales.Orders'),'TableHasPrimaryKey')
