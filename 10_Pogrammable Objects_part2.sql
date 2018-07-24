-- T-SQL Fundamentals
-- Chapter 10 Programming Objects
-- 1.Triggers
USE TSQLV4;
GO 
-- DML Trigger
IF OBJECT_ID('dbo.T1_Audit', 'U') IS NOT NULL DROP TABLE dbo.T1_Audit;
GO
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
GO

CREATE TABLE dbo.T1
(
	keycol  INT         NOT NULL PRIMARY KEY,
	datacol VARCHAR(10) NOT NULL
)

CREATE TABLE dbo.T1_Audit
(
	audit_lsn  INT         NOT NULL IDENTITY PRIMARY KEY,
	dt         DATETIME    NOT NULL DEFAULT(SYSDATETIME()),
	login_name sysname     NOT NULL DEFAULT(ORIGINAL_LOGIN()),
	keycol     INT         NOT NULL,
	datacol    VARCHAR(10) NOT NULL
)
---- create DML trigger
CREATE TRIGGER trg_T1_insert_audit ON dbo.T1 AFTER INSERT
AS
INSERT INTO dbo.T1_Audit(keycol, datacol)
	SELECT keycol, datacol FROM inserted;
GO
---- fires the trigger
INSERT INTO dbo.T1(keycol, datacol) VALUES(10, 'a');
INSERT INTO dbo.T1(keycol, datacol) VALUES(30, 'x');
INSERT INTO dbo.T1(keycol, datacol) VALUES(20, 'g');
SELECT * FROM dbo.T1_Audit;
---- clean up 
IF OBJECT_ID('dbo.T1_Audit', 'U') IS NOT NULL DROP TABLE dbo.T1_Audit;
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;


-- DDL Trigger
IF OBJECT_ID('dbo.AuditDDLEvents', 'U') IS NOT NULL DROP TABLE dbo.AuditDDLEvents;
GO

CREATE TABLE dbo.AuditDDLEvents
(
	audit_lsn INT NOT NULL IDENTITY,
	posttime DATETIME NOT NULL,
	eventtype sysname NOT NULL,
	loginname sysname NOT NULL,
	schemaname sysname NOT NULL,
	objectname sysname NOT NULL,
	targetobjectname sysname NULL,
	eventdata XML NOT NULL,
	CONSTRAINT PK_AuditDDLEvents PRIMARY KEY(audit_lsn)
)

---- create DDL Triggers
CREATE TRIGGER trg_audit_ddl_events
ON DATABASE FOR DDL_DATABASE_LEVEL_EVENTS
AS
SET NOCOUNT ON;
DECLARE @eventdata AS XML = eventdata();
INSERT INTO dbo.AuditDDLEvents(
	posttime, eventtype, loginname, schemaname,
	objectname, targetobjectname, eventdata)
VALUES(
	@eventdata.value('(/EVENT_INSTANCE/PostTime)[1]', 'VARCHAR(23)'),
	@eventdata.value('(/EVENT_INSTANCE/EventType)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/LoginName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/TargetObjectName)[1]', 'sysname'),
	@eventdata);
GO

CREATE TABLE dbo.T1(col1 INT NOT NULL PRIMARY KEY);
ALTER TABLE dbo.T1 ADD col2 INT NULL;
ALTER TABLE dbo.T1 ALTER COLUMN col2 INT NOT NULL;
CREATE NONCLUSTERED INDEX idx1 ON dbo.T1(col2);
GO 
SELECT * FROM dbo.AuditDDLEvents;

-- 2. Error Handling
---- show all warning messages in the system.
SELECT * FROM sys.messages;
---- Example 1
BEGIN TRY
	PRINT 10/0;
	PRINT 'No error';
END TRY
BEGIN CATCH
	PRINT 'Error';
END CATCH;
---- Example 2
USE TSQLV4;
GO

IF OBJECT_ID('dbo.Employees') IS NOT NULL DROP TABLE dbo.Employees;
GO

CREATE TABLE dbo.Employees
(
	 empid INT NOT NULL,
	 empname VARCHAR(25) NOT NULL,
	 mgrid INT NULL,
	 CONSTRAINT PK_Employees PRIMARY KEY(empid),
	 CONSTRAINT CHK_Employees_empid CHECK(empid > 0),
	 CONSTRAINT FK_Employees_Employees
	 FOREIGN KEY(mgrid) REFERENCES dbo.Employees(empid)
);
BEGIN TRY 
	INSERT INTO dbo.Employees(empid, empname, mgrid)
		VALUES(1, 'Emp1', NULL);
END TRY
BEGIN CATCH
	IF ERROR_NUMBER() = 2627
	BEGIN
		PRINT '  Handling PK violation...';
	END
	ELSE IF ERROR_NUMBER() = 547
	BEGIN
		PRINT '  Handling CHECK/FK constraint violation...';
	END
	ELSE IF ERROR_NUMBER() = 514
	BEGIN
		PRINT '  Handling NULL violation...';
	END
	ELSE IF ERROR_NUMBER() = 245
	BEGIN
		PRINT '  Handling conversion error...';
	END
	ELSE
	BEGIN
		PRINT 'Re-throwing error...';
		THROW; -- throw error.
	END
END CATCH

-- Note that you can create a stored procedure that encapsulates resusable error-handling code
IF OBJECT_ID('dbo.ErrInsertHandler', 'P') IS NOT NULL DROP PROC dbo.ErrInsertHandler;
GO

CREATE PROC dbo.ErrInsertHandler
AS
SET NOCOUNT ON;

IF ERROR_NUMBER() = 2627
BEGIN
	PRINT '  Handling PK violation...';
END
ELSE IF ERROR_NUMBER() = 547
BEGIN
	PRINT '  Handling CHECK/FK constraint violation...';
END
ELSE IF ERROR_NUMBER() = 514
BEGIN
	PRINT '  Handling NULL violation...';
END
ELSE IF ERROR_NUMBER() = 245
BEGIN
	PRINT '  Handling conversion error...';
END
GO

-- You can execute the error handling procedure in the CATCH block.
BEGIN TRY
	INSERT INTO dbo.Employees(empid, empname, mgrid)
		VALUES(1, 'Emp1', NULL);
END TRY
BEGIN CATCH
	IF ERROR_NUMBER() IN (2627, 547, 515, 245)
		EXEC dbo.ErrInsertHandler;
	ELSE
		THROW;
END CATCH;

