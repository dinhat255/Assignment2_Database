-- File: 05_CreateUser.sql
-- Tạo user sManager với quyền db_owner

USE ElearningDB;
GO

-- Kiểm tra và xóa user nếu đã tồn tại
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'sManager')
BEGIN
    DROP USER sManager;
    PRINT N'Đã xóa user sManager cũ';
END
GO

-- Kiểm tra và xóa login nếu đã tồn tại
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'sManager')
BEGIN
    DROP LOGIN sManager;
    PRINT N'Đã xóa login sManager cũ';
END
GO

-- Tạo SQL Server Login
CREATE LOGIN sManager 
WITH PASSWORD = 'sManager',
     DEFAULT_DATABASE = ElearningDB,
     CHECK_POLICY = OFF;
GO

-- Tạo Database User
USE ElearningDB;
CREATE USER sManager FOR LOGIN sManager;
GO

-- Gán quyền db_owner (full access)
ALTER ROLE db_owner ADD MEMBER sManager;
GO

PRINT N'========================================';
PRINT N'Da tao user sManager thanh cong!';
PRINT N'Login: sManager';
PRINT N'Password: sManager';
PRINT N'Role: db_owner (Full access)';
PRINT N'========================================';
GO

-- Kiểm tra quyền
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = 'sManager';
