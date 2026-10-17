Imports System
Imports System.Linq

' Enforces reset invalidation for Portal sessions; new logins also retain their encrypted password snapshot.
Public NotInheritable Class EmployeeSessionResetGuard
    Public Class Snapshot
        Public Property Password As String
        Public Property Epoch As Long
    End Class
    Public Shared Function Read(userID As Integer) As Snapshot
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of Snapshot)("IF OBJECT_ID('dbo.PasswordReset_AccountEpoch','U') IS NULL SELECT Password,CONVERT(bigint,0) Epoch FROM dbo.UsersMembers WHERE ID={0}; ELSE SELECT u.Password,ISNULL(e.Epoch,CONVERT(bigint,0)) Epoch FROM dbo.UsersMembers u LEFT JOIN dbo.PasswordReset_AccountEpoch e ON e.UserID=u.ID WHERE u.ID={0};", userID).FirstOrDefault()
        End Using
    End Function
End Class
