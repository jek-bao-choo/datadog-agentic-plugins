-- setup-dbm-user.sql — Create Datadog Database Monitoring user
-- Run with: sqlcmd -S localhost -U sa -P <password> -i setup-dbm-user.sql
-- Reference: https://docs.datadoghq.com/database_monitoring/setup_sql_server/selfhosted/

USE master;
GO

-- Create login for Datadog monitoring
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'datadog')
BEGIN
    CREATE LOGIN datadog WITH PASSWORD = 'CHANGE_ME_DD_DBM_PASSWORD';
END
GO

-- Grant server-level permissions
GRANT CONNECT ANY DATABASE TO datadog;
GRANT VIEW SERVER STATE TO datadog;
GRANT VIEW ANY DEFINITION TO datadog;
GO

-- Create user in the PGW database
USE [jek-database-pgw];
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'datadog')
BEGIN
    CREATE USER datadog FOR LOGIN datadog;
END
GO

PRINT 'Datadog DBM monitoring user created. Update the password in production!';
GO
