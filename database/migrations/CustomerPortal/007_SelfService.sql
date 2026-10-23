-- Customer mutations use their real CRM identity; no employee identity is fabricated.
ALTER TABLE dbo.CRM_Contacts ALTER COLUMN AddedUser int NULL;
IF COL_LENGTH('dbo.Customer_Portal_Activity','Entity') IS NULL ALTER TABLE dbo.Customer_Portal_Activity ADD Entity nvarchar(80) NULL,RecordID int NULL,Before_Data xml NULL,After_Data xml NULL;
ALTER TABLE dbo.Customer_Portal_Activity ALTER COLUMN AccountID int NULL;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_WriteCheck @AccountID int,@Stamp uniqueidentifier AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51910,'Write authorization requires a transaction.',1;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51910,N'السجل مشغول؛ أعد المحاولة.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l WITH(UPDLOCK,HOLDLOCK) JOIN dbo.CRM_Accounts a WITH(UPDLOCK,HOLDLOCK) ON a.ID=l.AccountID
 WHERE l.AccountID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0)
 THROW 51911,N'انتهت صلاحية الدخول؛ سجل الدخول مجددًا.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_SaveProfile @AccountID int,@Stamp uniqueidentifier,@Data xml,@Version binary(8),@Logo_Url nvarchar(260)=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
IF @Data IS NULL OR @Data.value('count(/row)','int')<>1 OR @Data.exist('/row/*[not(local-name()=("Name_AR","Name_EN","Phone","Email","Address","Country","Website","Registration_Number"))]')=1 THROW 51910,N'بيانات النموذج غير صحيحة.',1;
DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))>200 OR @Name_AR IS NULL THROW 51910,N'يرجى استكمال حقل الاسم بالعربية ضمن الطول المسموح.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))>200 THROW 51910,N'يرجى استكمال حقل الاسم بالإنجليزية ضمن الطول المسموح.',1;
DECLARE @Phone nvarchar(50)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))>50 THROW 51910,N'يرجى استكمال حقل Phone ضمن الطول المسموح.',1;
DECLARE @Email nvarchar(254)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))>254 THROW 51910,N'يرجى استكمال حقل Email ضمن الطول المسموح.',1;
DECLARE @Address nvarchar(500)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Address/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Address/text())[1]','nvarchar(max)'))>500 THROW 51910,N'يرجى استكمال حقل Address ضمن الطول المسموح.',1;
DECLARE @Country nvarchar(100)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Country/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Country/text())[1]','nvarchar(max)'))>100 THROW 51910,N'يرجى استكمال حقل Country ضمن الطول المسموح.',1;
DECLARE @Website nvarchar(500)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Website/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Website/text())[1]','nvarchar(max)'))>500 THROW 51910,N'يرجى استكمال حقل Website ضمن الطول المسموح.',1;
DECLARE @Registration_Number nvarchar(100)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Registration_Number/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Registration_Number/text())[1]','nvarchar(max)'))>100 THROW 51910,N'يرجى استكمال حقل Registration_Number ضمن الطول المسموح.',1;
IF @Email IS NOT NULL AND @Email NOT LIKE N'%_@_%._%' THROW 51910,N'البريد الإلكتروني غير صحيح.',1;
IF @Website IS NOT NULL AND @Website NOT LIKE N'https://_%' AND @Website NOT LIKE N'http://_%' THROW 51910,N'أدخل رابطًا يبدأ بـ https أو http.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Row_Version=@Version) THROW 51910,N'تم تعديل بياناتك؛ أعد فتح النموذج قبل الحفظ.',1;
IF @Logo_Url IS NOT NULL AND (@Logo_Url COLLATE Latin1_General_100_BIN2 NOT LIKE N'/FileManager/CustomerLogos/'+REPLICATE(N'[0-9a-f]',32)+N'.png' OR DATALENGTH(@Logo_Url)<>126) THROW 51910,N'مسار الشعار غير صحيح.',1;
IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID<>@AccountID AND (UPPER(LTRIM(RTRIM(Name_AR)))=UPPER(@Name_AR) OR (@Registration_Number IS NOT NULL AND Registration_Number=@Registration_Number))) THROW 51910,N'اسم العميل أو رقم التسجيل مستخدم مسبقًا.',1;
DECLARE @Before xml=(SELECT Name_AR,Name_EN,Phone,Email,Address,Country,Website,Registration_Number,Row_Version,CONVERT(bit,CASE WHEN Logo_Url IS NULL THEN 0 ELSE 1 END) HasLogo FROM dbo.CRM_Accounts WHERE ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
UPDATE dbo.CRM_Accounts SET Name_AR=@Name_AR,Name_EN=@Name_EN,Phone=@Phone,Email=@Email,Address=@Address,Country=@Country,Website=@Website,Registration_Number=@Registration_Number,Logo_Url=COALESCE(@Logo_Url,Logo_Url),Modified_User=NULL,Modified_Date=SYSDATETIME() WHERE ID=@AccountID;
DECLARE @After xml=(SELECT Name_AR,Name_EN,Phone,Email,Address,Country,Website,Registration_Number,Row_Version,CONVERT(bit,CASE WHEN Logo_Url IS NULL THEN 0 ELSE 1 END) HasLogo,CONVERT(bit,CASE WHEN @Logo_Url IS NULL THEN 0 ELSE 1 END) LogoChanged FROM dbo.CRM_Accounts WHERE ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note,Before_Data,After_Data) VALUES(@AccountID,'profile-update',N'Accounts',@AccountID,N'تعديل بيانات العميل من بوابة العميل',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_SaveContact @AccountID int,@Stamp uniqueidentifier,@ID int=0,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
IF @Data IS NULL OR @Data.value('count(/row)','int')<>1 OR @Data.exist('/row/*[not(local-name()=("Name_AR","Name_EN","Job_Title","Job_Title_EN","Phone","Email","Gender","Is_Active"))]')=1 THROW 51910,N'بيانات النموذج غير صحيحة.',1;
DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))>200 OR @Name_AR IS NULL THROW 51910,N'يرجى استكمال حقل الاسم بالعربية ضمن الطول المسموح.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))>200 OR @Name_EN IS NULL THROW 51910,N'يرجى استكمال حقل الاسم بالإنجليزية ضمن الطول المسموح.',1;
DECLARE @Job_Title nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Job_Title/text())[1]','nvarchar(max)'))),N'');
IF @Job_Title IS NULL OR LEN(@Data.value('(/row/Job_Title/text())[1]','nvarchar(max)'))>200 THROW 51910,N'أدخل المسمى الوظيفي بالعربية (حتى 200 حرف).',1;
DECLARE @Job_Title_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Job_Title_EN/text())[1]','nvarchar(max)'))),N'');
IF @Job_Title_EN IS NULL OR LEN(@Data.value('(/row/Job_Title_EN/text())[1]','nvarchar(max)'))>200 THROW 51910,N'أدخل المسمى الوظيفي بالإنجليزية (حتى 200 حرف).',1;
DECLARE @Phone nvarchar(50)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))>50 THROW 51910,N'يرجى استكمال حقل Phone ضمن الطول المسموح.',1;
DECLARE @Email nvarchar(254)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))>254 THROW 51910,N'يرجى استكمال حقل Email ضمن الطول المسموح.',1;
DECLARE @Gender nvarchar(20)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Gender/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Gender/text())[1]','nvarchar(max)'))>20 THROW 51910,N'يرجى استكمال حقل Gender ضمن الطول المسموح.',1;
IF @Email IS NOT NULL AND @Email NOT LIKE N'%_@_%._%' THROW 51910,N'البريد الإلكتروني غير صحيح.',1;
DECLARE @Active bit=TRY_CONVERT(bit,@Data.value('(/row/Is_Active/text())[1]','nvarchar(5)'));
IF @Active IS NULL OR @ID<0 THROW 51910,N'حالة جهة الاتصال غير صحيحة.',1;
IF @Gender IS NOT NULL AND @Gender NOT IN(N'M',N'F') THROW 51910,N'الجنس غير صحيح.',1;
IF @ID<>0 AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Contacts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND Account_ID=@AccountID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51910,N'جهة الاتصال غير متاحة أو تم تعديلها؛ حدّث القائمة.',1;
DECLARE @Before xml=(SELECT ID,Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Is_Deleted,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID AND Account_ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
DECLARE @New bit=CASE WHEN @ID=0 THEN 1 ELSE 0 END;
IF @ID=0 BEGIN INSERT dbo.CRM_Contacts(Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,AddedUser) VALUES(@AccountID,@Name_AR,@Name_EN,@Job_Title,@Job_Title_EN,@Phone,@Email,@Gender,@Active,NULL);SET @ID=CONVERT(int,SCOPE_IDENTITY());END
ELSE UPDATE dbo.CRM_Contacts SET Name_AR=@Name_AR,Name_EN=@Name_EN,Job_Title=@Job_Title,Job_Title_EN=@Job_Title_EN,Phone=@Phone,Email=@Email,Gender=@Gender,Is_Active=@Active,Modified_User=NULL,Modified_Date=SYSDATETIME() WHERE ID=@ID AND Account_ID=@AccountID;
DECLARE @After xml=(SELECT ID,Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Is_Deleted,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID AND Account_ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note,Before_Data,After_Data) VALUES(@AccountID,CASE WHEN @New=1 THEN 'contact-create' ELSE 'contact-update' END,N'Contacts',@ID,N'حفظ جهة اتصال من بوابة العميل',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_DeleteContact @AccountID int,@Stamp uniqueidentifier,@ID int,@Version binary(8) AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Contacts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND Account_ID=@AccountID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51910,N'جهة الاتصال غير متاحة أو تم تعديلها؛ حدّث القائمة.',1;
DECLARE @Before xml=(SELECT ID,Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Is_Deleted,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID AND Account_ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
UPDATE dbo.CRM_Contacts SET Is_Deleted=1,Is_Active=0,Modified_User=NULL,Modified_Date=SYSDATETIME() WHERE ID=@ID AND Account_ID=@AccountID;
DECLARE @After xml=(SELECT ID,Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Is_Deleted,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID AND Account_ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note,Before_Data,After_Data) VALUES(@AccountID,'contact-delete',N'Contacts',@ID,N'حذف جهة اتصال من بوابة العميل',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_LogActivity @AccountID int,@Stamp uniqueidentifier,@Action varchar(30),@RecordID int=NULL AS
BEGIN
 SET NOCOUNT ON;
 IF @Action NOT IN('dashboard-view','contact-view','logout') THROW 51910,N'الإجراء غير متاح.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE l.AccountID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @Action='contact-view' AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Contacts WHERE ID=@RecordID AND Account_ID=@AccountID AND Is_Deleted=0) THROW 51910,N'جهة الاتصال غير متاحة.',1;
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID) VALUES(@AccountID,@Action,CASE WHEN @Action='logout' THEN N'Customer_Session' WHEN @Action='contact-view' THEN N'Contacts' ELSE N'Accounts' END,CASE WHEN @Action='contact-view' THEN @RecordID ELSE @AccountID END);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_LogLoginFailure @Username nvarchar(100) AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @AccountID int=(SELECT AccountID FROM dbo.Customer_Logins WHERE NormalizedUsername=UPPER(LTRIM(RTRIM(@Username))));
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note) VALUES(@AccountID,'login-failed',N'Customer_Session',@AccountID,N'محاولة دخول غير ناجحة');
END;
GO
CREATE OR ALTER VIEW dbo.CRM_v_Activity AS
SELECT l.ID,l.Actor_ID,l.Account_ID,l.Entity,l.Record_ID,l.Action,l.Before_Data,l.After_Data,l.Note,l.AddedDate,
 u.FullName_Ar User_Name,a.Name_AR Account_Name,CONVERT(nvarchar(40),N'إدارة النظام') Source_Name
FROM dbo.CRM_Activity_Logs l LEFT JOIN dbo.UsersMembers u ON u.ID=l.Actor_ID LEFT JOIN dbo.CRM_Accounts a ON a.ID=l.Account_ID
UNION ALL
SELECT -x.ID,x.ActorID,x.AccountID,COALESCE(x.Entity,CASE WHEN x.Action IN('login','logout','credentials','login-failed') THEN N'Customer_Session' ELSE N'Accounts' END),COALESCE(x.RecordID,x.AccountID),
CASE x.Action WHEN 'credentials' THEN N'تحديث بيانات الدخول' WHEN 'login' THEN N'تسجيل الدخول كعميل' WHEN 'logout' THEN N'تسجيل الخروج' WHEN 'login-failed' THEN N'محاولة دخول فاشلة' WHEN 'dashboard-view' THEN N'عرض لوحة العميل' WHEN 'contact-view' THEN N'عرض جهة اتصال' WHEN 'profile-update' THEN N'تعديل بيانات العميل' WHEN 'contact-create' THEN N'إضافة جهة اتصال' WHEN 'contact-update' THEN N'تعديل جهة اتصال / الحالة' WHEN 'contact-delete' THEN N'حذف جهة اتصال' WHEN 'feedback' THEN CONCAT(N'تقديم ',COALESCE(x.FeedbackTypeTitle,N'طلب')) ELSE x.Action END,x.Before_Data,x.After_Data,x.Note,
 CONVERT(datetime2,x.CreatedUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Jordan Standard Time'),
 CASE WHEN x.ActorID IS NULL THEN COALESCE(a.Name_AR,N'زائر غير مصادق') ELSE u.FullName_Ar END,a.Name_AR,
 CASE WHEN x.ActorID IS NULL THEN N'بوابة العميل' ELSE N'إدارة النظام' END
FROM dbo.Customer_Portal_Activity x LEFT JOIN dbo.CRM_Accounts a ON a.ID=x.AccountID LEFT JOIN dbo.UsersMembers u ON u.ID=x.ActorID;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_Logs @Actor_ID int,@User_ID int=NULL,@From date=NULL,@To date=NULL,@Entity nvarchar(80)=NULL,@Account_ID int=NULL AS
BEGIN SET NOCOUNT ON;
 IF OBJECT_ID('dbo.CRM_v_Activity','V') IS NOT NULL BEGIN EXEC sys.sp_executesql N'SELECT * FROM dbo.CRM_v_Activity l WHERE dbo.CRM_CanAccess(@Actor_ID,l.Account_ID)=1 AND (l.Entity<>N''Customer_Session'' OR EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) AND (@User_ID IS NULL OR l.Actor_ID=@User_ID) AND (@From IS NULL OR l.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,l.AddedDate)<=@To) AND (@Entity IS NULL OR l.Entity=@Entity) AND (@Account_ID IS NULL OR l.Account_ID=@Account_ID) ORDER BY l.AddedDate DESC,l.ID DESC;',N'@Actor_ID int,@User_ID int,@From date,@To date,@Entity nvarchar(80),@Account_ID int',@Actor_ID,@User_ID,@From,@To,@Entity,@Account_ID;RETURN;END;
 SELECT l.*,u.FullName_Ar AS User_Name,a.Name_AR AS Account_Name,CONVERT(nvarchar(40),N'إدارة النظام') Source_Name FROM dbo.CRM_Activity_Logs l JOIN dbo.UsersMembers u ON u.ID=l.Actor_ID LEFT JOIN dbo.CRM_Accounts a ON a.ID=l.Account_ID
 WHERE dbo.CRM_CanAccess(@Actor_ID,l.Account_ID)=1 AND (@User_ID IS NULL OR l.Actor_ID=@User_ID) AND (@From IS NULL OR l.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,l.AddedDate)<=@To) AND (@Entity IS NULL OR l.Entity=@Entity) AND (@Account_ID IS NULL OR l.Account_ID=@Account_ID) ORDER BY l.ID DESC;
END
GO
CREATE OR ALTER PROCEDURE dbo.Customer_AdminData @Actor int,@AccountID int,@Section varchar(20)='login',@Brand int=0 AS
BEGIN
 SET NOCOUNT ON;EXEC dbo.Customer_AdminCheck @Actor;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Is_Deleted=0) THROW 51910,N'العميل غير متاح.',1;
 IF @Section='login' SELECT a.Name_AR,l.AccountID,l.Username,l.IsActive,l.LastLoginUtc,l.Version FROM dbo.CRM_Accounts a LEFT JOIN dbo.Customer_Logins l ON l.AccountID=a.ID WHERE a.ID=@AccountID;
 IF @Section='activity' SELECT TOP(100) CONVERT(datetime2,l.AddedDate AT TIME ZONE 'Jordan Standard Time' AT TIME ZONE 'UTC') CreatedUtc,l.Action,l.Note,l.User_Name ActorName,l.Source_Name FROM dbo.CRM_v_Activity l WHERE l.Account_ID=@AccountID ORDER BY l.AddedDate DESC,l.ID DESC;
END;
GO

IF OBJECT_ID('dbo.CustomerApi_Logout','P') IS NOT NULL EXEC(N'CREATE OR ALTER PROCEDURE dbo.CustomerApi_Logout @TokenHash binary(32) AS
BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRAN;
 DECLARE @Changed TABLE(AccountID int);
 UPDATE dbo.CustomerApi_Sessions SET RevokedUtc=SYSUTCDATETIME() OUTPUT inserted.AccountID INTO @Changed WHERE TokenHash=@TokenHash AND RevokedUtc IS NULL;
 INSERT dbo.Customer_Portal_Activity(AccountID,Action) SELECT AccountID,''logout'' FROM @Changed;
 COMMIT;END;
');
GO

CREATE OR ALTER PROCEDURE dbo.Customer_SaveLogin @Actor int,@AccountID int,@Username nvarchar(100),@Hash varbinary(32)=NULL,@Salt varbinary(32)=NULL,@Iterations int=210000,@Active bit=1,@Version binary(8)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.Customer_AdminCheck @Actor;
 SET @Username=LTRIM(RTRIM(@Username));
 IF NULLIF(@Username,'') IS NULL OR LEN(@Username)<3 OR @Iterations<100000 THROW 51910,N'أدخل اسم مستخدم من 3 إلى 100 حرف.',1;
 IF @Hash IS NOT NULL AND (DATALENGTH(@Hash)<>32 OR @Salt IS NULL OR DATALENGTH(@Salt)<>32) THROW 51910,N'بيانات كلمة المرور غير صحيحة.',1;
 BEGIN TRAN;
 DECLARE @Before xml=(SELECT Username,IsActive FROM dbo.Customer_Logins WHERE AccountID=@AccountID FOR XML PATH('login'),TYPE);
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@AccountID AND Is_Deleted=0) BEGIN ROLLBACK;THROW 51910,N'العميل غير متاح.',1;END;
 IF EXISTS(SELECT 1 FROM dbo.Customer_Logins WITH(UPDLOCK,HOLDLOCK) WHERE NormalizedUsername=UPPER(@Username) AND AccountID<>@AccountID) BEGIN ROLLBACK;THROW 51910,N'اسم المستخدم محجوز لعميل آخر.',1;END;
 IF EXISTS(SELECT 1 FROM dbo.Customer_Logins WITH(UPDLOCK,HOLDLOCK) WHERE AccountID=@AccountID)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins WHERE AccountID=@AccountID AND Version=@Version) BEGIN ROLLBACK;THROW 51910,N'تغير الحساب؛ حدّث الصفحة قبل الحفظ.',1;END;
  UPDATE dbo.Customer_Logins SET Username=@Username,PasswordHash=COALESCE(@Hash,PasswordHash),Salt=CASE WHEN @Hash IS NULL THEN Salt ELSE @Salt END,
  Iterations=CASE WHEN @Hash IS NULL THEN Iterations ELSE @Iterations END,IsActive=@Active,SecurityStamp=NEWID(),FailedAttempts=0,LockedUntil=NULL,ModifiedBy=@Actor,ModifiedUtc=SYSUTCDATETIME() WHERE AccountID=@AccountID;
 END
 ELSE BEGIN
  IF @Hash IS NULL BEGIN ROLLBACK;THROW 51910,N'كلمة المرور مطلوبة للحساب الجديد.',1;END;
  INSERT dbo.Customer_Logins(AccountID,Username,PasswordHash,Salt,Iterations,IsActive,ModifiedBy) VALUES(@AccountID,@Username,@Hash,@Salt,@Iterations,@Active,@Actor);
 END;
 DECLARE @After xml=(SELECT Username,IsActive,CONVERT(bit,CASE WHEN @Hash IS NULL THEN 0 ELSE 1 END) PasswordChanged FROM dbo.Customer_Logins WHERE AccountID=@AccountID FOR XML PATH('login'),TYPE);
 INSERT dbo.Customer_Portal_Activity(AccountID,ActorID,Action,Entity,RecordID,Before_Data,After_Data,Note) VALUES(@AccountID,@Actor,'credentials',N'Customer_Session',@AccountID,@Before,@After,N'تم تحديث اسم الدخول أو حالة الحساب أو إعادة تعيين كلمة المرور.');
 COMMIT;
END;
GO
