-- Daily activity uses Jordan calendar dates; retain existing report dimensions.
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Statistics @Actor int,@Type int=0,@Status int=0,@Identity int=0,@Brand int=0,@Branch int=0,@From date=NULL,@To date=NULL,@Source int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'الإحصائيات لمدير النظام فقط.',1;
 SELECT r.Type,r.Status,r.DiscloseIdentity,r.Brand_ID,r.Branch_ID,r.AddedDate,r.CloseDate,r.SourceType INTO #R
 FROM dbo.Employee_Feedback_Requests r LEFT JOIN dbo.UsersMembers e ON e.ID=r.EmployeeID
 WHERE (@Type=0 OR r.Type=@Type) AND (@Status=0 OR r.Status=@Status OR (@Status=4 AND r.Status<>3))
 AND (@Identity=0 OR r.DiscloseIdentity=CASE WHEN @Identity=1 THEN 1 ELSE 0 END)
 AND (@Brand=0 OR r.Brand_ID=@Brand) AND (@Branch=0 OR r.Branch_ID=@Branch) AND (@Source=0 OR r.SourceType=@Source)
 AND (@From IS NULL OR r.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,r.AddedDate)<=@To);
 SELECT CAST('type' AS varchar(20)) Dimension,r.Type Value,CAST(t.Title_Ar AS nvarchar(300)) Label,COUNT(*) Total FROM #R r JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type GROUP BY r.Type,t.Title_Ar
 UNION ALL SELECT 'status',CASE WHEN Status=3 THEN 3 ELSE 4 END,CASE WHEN Status=3 THEN N'منتهي' ELSE N'فعال' END,COUNT(*) FROM #R GROUP BY CASE WHEN Status=3 THEN 3 ELSE 4 END,CASE WHEN Status=3 THEN N'منتهي' ELSE N'فعال' END
 UNION ALL SELECT 'identity',CASE WHEN DiscloseIdentity=1 THEN 1 ELSE 2 END,CASE WHEN DiscloseIdentity=1 THEN N'معروف الهوية' ELSE N'مجهول الهوية' END,COUNT(*) FROM #R GROUP BY DiscloseIdentity
 UNION ALL SELECT 'brand',ISNULL(r.Brand_ID,0),ISNULL(b.Title_Ar,N'غير محدد'),COUNT(*) FROM #R r LEFT JOIN dbo.Brands b ON b.ID=r.Brand_ID GROUP BY r.Brand_ID,b.Title_Ar
 UNION ALL SELECT 'branch',ISNULL(r.Branch_ID,0),ISNULL(b.Title_Ar,N'غير محدد'),COUNT(*) FROM #R r LEFT JOIN dbo.Branches b ON b.ID=r.Branch_ID GROUP BY r.Branch_ID,b.Title_Ar
 UNION ALL SELECT 'source',SourceType,CASE SourceType WHEN 1 THEN N'موظف' ELSE N'زبون' END,COUNT(*) FROM #R GROUP BY SourceType
 UNION ALL SELECT 'month',CONVERT(int,CONVERT(char(6),AddedDate,112)),CONVERT(nvarchar(7),AddedDate,126),COUNT(*) FROM #R GROUP BY CONVERT(int,CONVERT(char(6),AddedDate,112)),CONVERT(nvarchar(7),AddedDate,126)
 UNION ALL SELECT 'day',CONVERT(int,CONVERT(char(8),d.LocalDate,112)),CONVERT(nvarchar(10),d.LocalDate,23),COUNT(*)
 FROM #R CROSS APPLY(SELECT CONVERT(date,AddedDate AT TIME ZONE 'UTC' AT TIME ZONE 'Jordan Standard Time') LocalDate) d
 WHERE d.LocalDate BETWEEN DATEADD(day,-6,CONVERT(date,GETUTCDATE() AT TIME ZONE 'UTC' AT TIME ZONE 'Jordan Standard Time')) AND CONVERT(date,GETUTCDATE() AT TIME ZONE 'UTC' AT TIME ZONE 'Jordan Standard Time')
 GROUP BY d.LocalDate;
END;
GO
