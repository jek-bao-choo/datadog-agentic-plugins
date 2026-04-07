-- setup-mssql.sql — Create payment gateway database, tables, and seed data
-- Run with: sqlcmd -S localhost -U sa -P <password> -i setup-mssql.sql

USE master;
GO

-- Create database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'jek-database-pgw')
BEGIN
    CREATE DATABASE [jek-database-pgw];
END
GO

USE [jek-database-pgw];
GO

-- Table: transactions (POS → PGW transaction records)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'jek-table-transactions')
BEGIN
    CREATE TABLE [jek-table-transactions] (
        id INT IDENTITY(1,1) PRIMARY KEY,
        txid VARCHAR(50) NOT NULL,
        molcode VARCHAR(10) NOT NULL,
        barcode VARCHAR(20),
        staffid VARCHAR(20),
        bdate DATE NOT NULL,
        status VARCHAR(10) DEFAULT 'pending',
        response_code VARCHAR(10),
        created_at DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Table: payments (PGW → FIUU payment records)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'jek-table-payments')
BEGIN
    CREATE TABLE [jek-table-payments] (
        payment_id INT IDENTITY(1,1) PRIMARY KEY,
        txid VARCHAR(50) NOT NULL,
        reference_id VARCHAR(50),
        amount DECIMAL(10,2),
        provider VARCHAR(20) DEFAULT 'fiuu',
        response_code VARCHAR(10),
        response_body NVARCHAR(MAX),
        created_at DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Table: audit log (XML/JSON payload storage)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'jek-table-audit-log')
BEGIN
    CREATE TABLE [jek-table-audit-log] (
        log_id INT IDENTITY(1,1) PRIMARY KEY,
        txid VARCHAR(50) NOT NULL,
        action VARCHAR(50) NOT NULL,
        payload_xml NVARCHAR(MAX),
        payload_json NVARCHAR(MAX),
        source_ip VARCHAR(45),
        timestamp DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Seed 100 rows of dummy transaction data
DECLARE @i INT = 1;
WHILE @i <= 100
BEGIN
    DECLARE @txid VARCHAR(50) = 'jek-tx-' + RIGHT('00000' + CAST(@i AS VARCHAR), 5);
    DECLARE @status VARCHAR(10) = CASE
        WHEN @i % 10 < 7 THEN 'success'
        WHEN @i % 10 < 9 THEN 'failed'
        ELSE 'timeout'
    END;
    DECLARE @respcode VARCHAR(10) = CASE
        WHEN @status = 'success' THEN '000'
        WHEN @status = 'failed' THEN '999'
        ELSE '520'
    END;

    INSERT INTO [jek-table-transactions] (txid, molcode, barcode, staffid, bdate, status, response_code)
    VALUES (@txid, 'M200', '9555397302301', 'jek-staff-001', GETDATE(), @status, @respcode);

    INSERT INTO [jek-table-payments] (txid, reference_id, amount, provider, response_code)
    VALUES (@txid, @txid, 10.00 + (@i * 0.5), 'fiuu', @respcode);

    INSERT INTO [jek-table-audit-log] (txid, action, payload_xml, source_ip)
    VALUES (@txid, 'stock/TX021',
        '<request><molcode>M200</molcode><txid>' + @txid + '</txid><barcode1>9555397302301</barcode1></request>',
        '10.0.0.100');

    SET @i = @i + 1;
END
GO

PRINT 'Database jek-database-pgw created with 100 seed rows in each table.';
GO
