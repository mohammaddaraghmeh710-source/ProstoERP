using System.Collections.Generic;
using System.Data;
using ProstoERP.Application.Data;
using ProstoERP.Infrastructure.Mobile.Data;
namespace ProstoERP.Infrastructure.Mobile.Features.Correspondence
{
    internal static class CorrespondenceStatements
    {
        internal static void Register(IDictionary<MobileStatement, MobileStatementDefinition> statements)
        {
            statements.Add(MobileStatement.Correspondence_MobileApiCorrespondenceActor, new MobileStatementDefinition("dbo.MobileApi_CorrespondenceActor", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_DetailCorrespondenceAccess, new MobileStatementDefinition("SELECT IsParticipant,IsAdmin FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ID", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_CorrespondenceDetail, new MobileStatementDefinition("dbo.Correspondence_Detail", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_VisitCorrespondenceAudit, new MobileStatementDefinition("SELECT 1 Found FROM dbo.Correspondence_Audit WHERE ThreadID=@ID AND ActorID=@Actor AND EventID=@Event AND Action='view'", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_CorrespondenceCatalogList, new MobileStatementDefinition("dbo.Correspondence_CatalogList", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_OptionsBrands, new MobileStatementDefinition("SELECT ID,Title_Ar Title FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_OptionsCorrespondenceAllowedRecipients, new MobileStatementDefinition("SELECT DISTINCT b.ID,b.Title_Ar Title FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) r JOIN dbo.Branches b ON b.ID=r.Branch_ID ORDER BY Title", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_OptionsCorrespondenceAllowedRecipients2, new MobileStatementDefinition("SELECT DISTINCT s.ID,s.Title_Ar Title FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) r JOIN dbo.Shift s ON s.ID=r.Shif_ID ORDER BY Title", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_CorrespondenceOptions, new MobileStatementDefinition("dbo.Correspondence_Options", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_RecipientsCorrespondenceAllowedRecipients, new MobileStatementDefinition(@"SELECT ID,FullName_Ar,Type,Brand_ID,Branch_ID,Shif_ID INTO #Recipients FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand)
WHERE (@Branch=0 OR Branch_ID=@Branch) AND (@Shift=0 OR Shif_ID=@Shift) AND (@Search='' OR FullName_Ar LIKE N'%'+@Search+N'%');
SELECT COUNT(*) TotalItems FROM #Recipients;
SELECT * FROM #Recipients ORDER BY FullName_Ar,ID OFFSET @Skip ROWS FETCH NEXT @Size ROWS ONLY;", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_MobileApiCorrespondenceList, new MobileStatementDefinition("dbo.MobileApi_CorrespondenceList", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_CorrespondenceLogView, new MobileStatementDefinition("dbo.Correspondence_LogView", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_CorrespondenceOrganization, new MobileStatementDefinition("dbo.Correspondence_Organization", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_CorrespondenceRelated, new MobileStatementDefinition("dbo.Correspondence_Related", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_CorrespondenceAuditList, new MobileStatementDefinition("dbo.Correspondence_AuditList", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_MobileApiCorrespondenceMessages, new MobileStatementDefinition("dbo.MobileApi_CorrespondenceMessages", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_UploadCorrespondenceAllowedRecipients, new MobileStatementDefinition("DECLARE @x xml=@IDs; SELECT ID FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) WHERE ID IN(SELECT n.value('@id','int') FROM @x.nodes('/items/item')x(n))", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_InsertCorrespondenceThread, new MobileStatementDefinition("dbo.Insert_Correspondence_Thread", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_InsertCorrespondenceThreadMessage, new MobileStatementDefinition("dbo.Insert_Correspondence_Thread_Message", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_UpdateCorrespondenceThreadClose, new MobileStatementDefinition("dbo.Update_Correspondence_Thread_Close", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_ReadCorrespondenceThreadMessages, new MobileStatementDefinition("DECLARE @x xml=@IDs; SELECT ID FROM dbo.Correspondence_Thread_Messages WHERE ThreadID=@ID AND ReceivedID=@Actor AND ID IN(SELECT n.value('@id','int') FROM @x.nodes('/items/item')x(n))", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_UpdateCorrespondenceMessagesRead, new MobileStatementDefinition("dbo.Update_Correspondence_Messages_Read", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_CorrespondenceArchive, new MobileStatementDefinition("dbo.Correspondence_Archive", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_NotificationsCorrespondenceNotifications, new MobileStatementDefinition(@"SELECT n.ID,n.ThreadID,n.MessageID,n.SendDate,n.IsRead,t.Title INTO #Notices FROM dbo.Correspondence_Notifications n
JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=n.ThreadID AND a.IsParticipant=1 JOIN dbo.Correspondence_Threads t ON t.ID=n.ThreadID WHERE n.UserID=@Actor;
SELECT COUNT(*) TotalItems FROM #Notices WHERE @Unread=0 OR ISNULL(IsRead,0)=0;
SELECT COUNT(*) UnreadNotifications FROM #Notices WHERE ISNULL(IsRead,0)=0;
SELECT * FROM #Notices WHERE @Unread=0 OR ISNULL(IsRead,0)=0 ORDER BY ID DESC OFFSET @Skip ROWS FETCH NEXT @Size ROWS ONLY;", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_SelectCorrespondenceUnreadCount, new MobileStatementDefinition("dbo.Select_Correspondence_UnreadCount", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Correspondence_NotificationReadN, new MobileStatementDefinition(@"UPDATE n SET IsRead=1 OUTPUT inserted.ID FROM dbo.Correspondence_Notifications n
JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=n.ThreadID AND a.IsParticipant=1 WHERE n.ID=@ID AND n.UserID=@Actor;", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_ReplayLock, new MobileStatementDefinition("DECLARE @Result int;EXEC @Result=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;IF @Result<0 THROW 51802,'Operation busy.',1;", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_ReplayMobileApiCorrespondenceEvents, new MobileStatementDefinition("SELECT PayloadHash,ResultJson FROM dbo.MobileApi_CorrespondenceEvents WHERE ActorID=@Actor AND OperationID=@Operation", CommandType.Text));
            statements.Add(MobileStatement.Correspondence_RecordLock, new MobileStatementDefinition("INSERT dbo.MobileApi_CorrespondenceEvents(ActorID,OperationID,PayloadHash,Action,ResultJson,OccurredAt) VALUES(@Actor,@Operation,@Hash,@Action,@Json,@Occurred)", CommandType.Text));
        }
    }
}
