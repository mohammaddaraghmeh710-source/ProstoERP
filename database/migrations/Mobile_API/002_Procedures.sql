CREATE OR ALTER PROCEDURE dbo.MobileApi_Login
 @Username nvarchar(250), @EncryptedPassword nvarchar(max), @TokenHash binary(32),
 @IdleMinutes int, @MaximumMinutes int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @IdleMinutes<1 OR @MaximumMinutes<@IdleMinutes THROW 51700,'Invalid session settings.',1;
 DECLARE @UserID int,@Now datetime2(0)=SYSUTCDATETIME();
 BEGIN TRANSACTION;
 SELECT @UserID=u.ID FROM dbo.UsersMembers u WITH(HOLDLOCK)
 WHERE u.UserName=@Username AND u.Password COLLATE Latin1_General_100_BIN2=@EncryptedPassword COLLATE Latin1_General_100_BIN2
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0;
 IF @UserID IS NULL BEGIN COMMIT; RETURN; END;
 INSERT dbo.MobileApi_Sessions(TokenHash,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc)
 VALUES(@TokenHash,@UserID,HASHBYTES('SHA2_256',CONVERT(varbinary(max),@EncryptedPassword)),
 @Now,@Now,DATEADD(minute,@IdleMinutes,@Now),DATEADD(minute,@MaximumMinutes,@Now));
 -- Explicit allowlist: every current employee field except Password; never SELECT u.*.
 SELECT u.ID,u.Type,u.Type UserTypeID,u.Employee_Number,u.FullName_Ar,u.Fullname_En,u.User_Image,
 u.PhoneNumber,u.MobileNumber,u.Email,u.Brand_ID,u.Branch_ID,u.Department_ID,u.JobTitle_ID,u.Shif_ID,
 u.Gender,u.Nationality,u.UserName,u.Status,u.Item_Order,u.AddedUser,u.AddedDate,u.ModifyUser,u.ModifyDate,u.IsDeleted,u.IsActive,
 t.Title_Ar UserType_Ar,t.Title_En UserType_En,b.Title_Ar Brand_Ar,b.Title_En Brand_En,
 br.Title_Ar Branch_Ar,br.Title_En Branch_En,d.Title_Ar Department_Ar,d.Title_En Department_En,
 j.Title_Ar JobTitle_Ar,j.Title_En JobTitle_En,s.Title_Ar Shift_Ar,s.Title_En Shift_En,
 g.Title_Ar Gender_Ar,g.Title_En Gender_En,n.Title_Ar Nationality_Ar,n.Title_En Nationality_En
 FROM dbo.UsersMembers u
 LEFT JOIN dbo.Users_Types t ON t.ID=u.Type
 LEFT JOIN dbo.Brands b ON b.ID=u.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=u.Branch_ID
 LEFT JOIN dbo.Departments d ON d.ID=u.Department_ID LEFT JOIN dbo.JobTitles j ON j.ID=u.JobTitle_ID
 LEFT JOIN dbo.Shift s ON s.ID=u.Shif_ID LEFT JOIN dbo.Genders g ON g.ID=u.Gender
 LEFT JOIN dbo.Nationalities n ON n.ID=u.Nationality WHERE u.ID=@UserID;
 SELECT ExpiresUtc ExpiresAt,AbsoluteExpiresUtc AbsoluteExpiresAt FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash;
 COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_Authenticate
 @TokenHash binary(32),@IdleMinutes int
AS
BEGIN
 SET NOCOUNT ON;
 IF @IdleMinutes<1 THROW 51700,'Invalid session settings.',1;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME();
 -- One atomic write prevents concurrent requests from reviving expired/revoked sessions.
 UPDATE s SET LastSeenUtc=@Now,
 ExpiresUtc=CASE WHEN DATEADD(minute,@IdleMinutes,@Now)<s.AbsoluteExpiresUtc
 THEN DATEADD(minute,@IdleMinutes,@Now) ELSE s.AbsoluteExpiresUtc END
 OUTPUT inserted.UserID,inserted.ExpiresUtc ExpiresAt,inserted.AbsoluteExpiresUtc AbsoluteExpiresAt
 FROM dbo.MobileApi_Sessions s JOIN dbo.UsersMembers u ON u.ID=s.UserID
 WHERE s.TokenHash=@TokenHash AND s.RevokedUtc IS NULL AND s.ExpiresUtc>@Now AND s.AbsoluteExpiresUtc>@Now
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0
 AND s.PasswordFingerprint=HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password));
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_Logout @TokenHash binary(32)
AS
BEGIN
 SET NOCOUNT ON;
 UPDATE dbo.MobileApi_Sessions SET RevokedUtc=SYSUTCDATETIME() WHERE TokenHash=@TokenHash AND RevokedUtc IS NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_News
AS
BEGIN
 SET NOCOUNT ON;
 SELECT PID,Title_AR,Title_En,Brief_Ar,Brief_En,Details,Image,Date,Item_Order,
 AddedUser,AddedDate,ModifyUser,ModifyDate,IsDeleted,IsActive
 FROM dbo.News WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Item_Order,Date DESC,PID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_InfoPages @Actor int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Role int,@Brand int,@Now datetime2(0)=SYSUTCDATETIME();
 BEGIN TRANSACTION;
 SELECT @Role=Type,@Brand=Brand_ID FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Role IS NULL THROW 51701,'Invalid session user.',1;
 -- Match portal viewing: brand membership AND type permissions; management preview is separate.
 SELECT p.ID,p.Title_Ar,p.Title_En,p.Summary_Ar,p.Summary_En,p.Details_Ar,p.Details_En,
 p.Item_Order,p.IsPublished,p.PublishMode,p.StartUtc,p.EndUtc,p.VersionNumber,p.CreatedUtc,p.ModifiedUtc,
 p.AllUserTypes,p.AccessRevision
 INTO #Pages FROM dbo.Information_Pages p WITH(HOLDLOCK)
 WHERE p.IsDeleted=0 AND p.IsPublished=1
 AND EXISTS(SELECT 1 FROM dbo.Information_Pages_ForBrand(@Brand) bp WHERE bp.PageID=p.ID)
 AND (p.PublishMode='immediate' OR (p.PublishMode='scheduled' AND @Now>=p.StartUtc AND @Now<p.EndUtc))
 AND (@Role=1 OR p.AllUserTypes=1 OR EXISTS(
 SELECT 1 FROM dbo.Information_Page_Roles r WITH(HOLDLOCK)
 JOIN dbo.Users_Types t WITH(HOLDLOCK) ON t.ID=r.UserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0
 WHERE r.PageID=p.ID AND r.UserTypeID=@Role));
 SELECT * FROM #Pages ORDER BY Item_Order,ID;
 -- Effective allowed IDs: expand AllUserTypes and include the portal admin override.
 SELECT p.ID PageID,t.ID UserTypeID FROM #Pages p CROSS JOIN dbo.Users_Types t WITH(HOLDLOCK)
 WHERE t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0
 AND (t.ID=1 OR p.AllUserTypes=1 OR EXISTS(SELECT 1 FROM dbo.Information_Page_Roles r WITH(HOLDLOCK)
 WHERE r.PageID=p.ID AND r.UserTypeID=t.ID)) ORDER BY p.ID,t.ID;
 COMMIT;
END;
