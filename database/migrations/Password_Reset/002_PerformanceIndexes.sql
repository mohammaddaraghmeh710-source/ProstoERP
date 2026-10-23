-- Additive indexes: reduce employee/rate-limit lookup scans and lock footprint.
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.UsersMembers') AND name='IX_UsersMembers_EmployeeNumber')
 CREATE INDEX IX_UsersMembers_EmployeeNumber ON dbo.UsersMembers(Employee_Number) INCLUDE(IsDeleted);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.PasswordReset_Challenges') AND name='IX_PasswordReset_UserPending')
 CREATE INDEX IX_PasswordReset_UserPending ON dbo.PasswordReset_Challenges(UserID,Invalidated) WHERE UsedUtc IS NULL;
GO
