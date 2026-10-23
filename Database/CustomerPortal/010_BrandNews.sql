-- Customer news is selected only through the authenticated account's current active brand.
CREATE OR ALTER PROCEDURE dbo.Customer_News @AccountID int,@Stamp uniqueidentifier,@ID int=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 DECLARE @Brand int=(SELECT a.Brand_ID FROM dbo.CRM_Accounts a JOIN dbo.Brands b ON b.ID=a.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE a.ID=@AccountID);
 IF @ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.News WITH(HOLDLOCK) WHERE PID=@ID AND Brand_ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
  THROW 51912,N'الخبر غير متاح.',1;
 SELECT PID,Title_AR,Title_En,Brief_Ar,Brief_En,Image,[Date],CASE WHEN @ID IS NULL THEN NULL ELSE Details END Details,CASE WHEN @ID IS NULL THEN NULL ELSE Details_EN END Details_EN
 FROM dbo.News WITH(HOLDLOCK) WHERE Brand_ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@ID IS NULL OR PID=@ID)
 ORDER BY Item_Order,[Date] DESC,PID DESC;
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note)
 VALUES(@AccountID,CASE WHEN @ID IS NULL THEN 'news-list' ELSE 'news-details' END,N'News',@ID,CASE WHEN @ID IS NULL THEN N'عرض أخبار العلامة التجارية' ELSE N'عرض تفاصيل خبر العلامة التجارية' END);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH;
END;
GO
