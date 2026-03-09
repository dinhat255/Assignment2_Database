-- Create Database User: sManager
-- Assignment 2 - Part 3.I (0.5 point)

USE ElearningDB;
GO

-- Create SQL Server Login (if not exists)
IF NOT EXISTS (SELECT *
FROM sys.server_principals
WHERE name = 'sManager')
BEGIN
    CREATE LOGIN sManager WITH PASSWORD = 'sManager';
    PRINT 'Login sManager created successfully.';
END
ELSE
BEGIN
    PRINT 'Login sManager already exists.';
END
GO

-- Create Database User for the Login (if not exists)
IF NOT EXISTS (SELECT *
FROM sys.database_principals
WHERE name = 'sManager')
BEGIN
    CREATE USER sManager FOR LOGIN sManager;
    PRINT 'User sManager created successfully.';
END
ELSE
BEGIN
    PRINT 'User sManager already exists.';
END
GO

-- Grant ALL access rights to sManager
ALTER ROLE db_owner ADD MEMBER sManager;
PRINT 'sManager added to db_owner role - Full access granted.';
GO

-- Verify the user and permissions
SELECT
    dp.name AS UserName,
    dp.type_desc AS UserType,
    r.name AS RoleName
FROM sys.database_principals dp
    LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
    LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = 'sManager'
ORDER BY dp.name, r.name;
GO

PRINT '==============================================';
PRINT 'User sManager setup completed!';
PRINT 'Login credentials:';
PRINT '  Username: sManager';
PRINT '  Password: sManager';
PRINT '  Roles: db_owner (full access)';
PRINT '==============================================';
GO
