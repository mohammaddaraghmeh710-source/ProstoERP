using System.Collections.Generic;
using System.Data;
using ProstoERP.Application.Data;
using ProstoERP.Infrastructure.Mobile.Data;
namespace ProstoERP.Infrastructure.Mobile.Features.CustomerPortal
{
    internal static class CustomerPortalStatements
    {
        internal static void Register(IDictionary<MobileStatement, MobileStatementDefinition> statements)
        {
            statements.Add(MobileStatement.CustomerPortal_CustomerApiCheckLoginRate, new MobileStatementDefinition("dbo.CustomerApi_CheckLoginRate", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerCredentials, new MobileStatementDefinition("dbo.Customer_Credentials", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerLoginResult, new MobileStatementDefinition("dbo.Customer_LoginResult", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerApiCreateSession, new MobileStatementDefinition("dbo.CustomerApi_CreateSession", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerApiLogout, new MobileStatementDefinition("dbo.CustomerApi_Logout", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_RequestAccessCustomerApiGuideOperations, new MobileStatementDefinition("SELECT BatchID,PayloadHash FROM dbo.CustomerApi_GuideOperations WHERE AccountID=@Account AND OperationID=@Operation", CommandType.Text));
            statements.Add(MobileStatement.CustomerPortal_RequestAccessLock, new MobileStatementDefinition("INSERT dbo.CustomerApi_GuideOperations(AccountID,OperationID,PayloadHash,BatchID) VALUES(@Account,@Operation,@Hash,@Batch)", CommandType.Text));
            statements.Add(MobileStatement.CustomerPortal_SubmitFeedbackCustomerPortalFeedback, new MobileStatementDefinition("SELECT f.RequestID,o.PayloadHash FROM dbo.Customer_Portal_Feedback f LEFT JOIN dbo.CustomerApi_FeedbackOperations o ON o.AccountID=f.AccountID AND o.OperationID=f.OperationID WHERE f.AccountID=@Account AND f.OperationID=@Operation", CommandType.Text));
            statements.Add(MobileStatement.CustomerPortal_SubmitFeedbackLock, new MobileStatementDefinition("INSERT dbo.CustomerApi_FeedbackOperations(AccountID,OperationID,PayloadHash) VALUES(@Account,@Operation,@Hash)", CommandType.Text));
            statements.Add(MobileStatement.CustomerPortal_LockLock, new MobileStatementDefinition("DECLARE @Result int;EXEC @Result=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;IF @Result<0 THROW 51802,'Operation busy.',1;", CommandType.Text));
            statements.Add(MobileStatement.CustomerPortal_CustomerSession, new MobileStatementDefinition("dbo.Customer_Session", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerWorkGuide, new MobileStatementDefinition("dbo.Customer_WorkGuide", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerApiGuide, new MobileStatementDefinition("dbo.CustomerApi_Guide", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerGuide, new MobileStatementDefinition("dbo.Customer_Guide", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerLogDocument, new MobileStatementDefinition("dbo.Customer_LogDocument", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerFeedbackOptions, new MobileStatementDefinition("dbo.Customer_FeedbackOptions", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerApiFeedback, new MobileStatementDefinition("dbo.CustomerApi_Feedback", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerPortal_CustomerSubmitFeedback, new MobileStatementDefinition("dbo.Customer_SubmitFeedback", CommandType.StoredProcedure));
        }
    }
}
