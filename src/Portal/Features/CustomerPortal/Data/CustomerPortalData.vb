Imports System.Data.SqlClient
Imports System.Security.Cryptography

<Serializable>
Public Class CustomerIdentity
    Public Property AccountID As Integer
    Public Property Name As String
    Public Property Stamp As Guid
End Class

Public NotInheritable Class CustomerPortalData
    Public Shared Property Current As CustomerIdentity
        Get
            Return TryCast(HttpContext.Current.Session("CustomerIdentity"), CustomerIdentity)
        End Get
        Set
            HttpContext.Current.Session("CustomerIdentity") = value
        End Set
    End Property
    Public Shared Function Query(name As String, ParamArray parameters As System.Data.SqlClient.SqlParameter()) As DataTable
        Return PortalSqlData.Query(name, parameters)
    End Function
    Public Shared Function P(name As String, kind As SqlDbType, value As Object, Optional size As Integer = 0) As System.Data.SqlClient.SqlParameter
        Return PortalSqlData.Parameter(name, kind, value, size)
    End Function

    Public Shared Function CustomerQuery(name As String, ParamArray parameters As SqlParameter()) _
        As DataTable
        If Current Is Nothing Then Throw New HttpException(401, "يلزم تسجيل دخول العميل")
        Dim _
            args As _
                New List(Of SqlParameter) _
                From {P("@AccountID", SqlDbType.Int, Current.AccountID),
                P("@Stamp", SqlDbType.UniqueIdentifier, Current.Stamp)}
        args.AddRange(parameters)
        Return Query(name, args.ToArray())
    End Function

    Public Shared Function RequireSession() As DataRow
        Return CustomerQuery("dbo.Customer_Session").Rows(0)
    End Function

    Public Shared Function HashPassword(password As String, salt As Byte(), iterations As Integer) As Byte()
        Using hash As New Rfc2898DeriveBytes(password, salt, iterations, HashAlgorithmName.SHA256)
            Return hash.GetBytes(32)
        End Using
    End Function

    Public Shared Function NewSalt() As Byte()
        Dim result(31) As Byte
        Using rng = RandomNumberGenerator.Create()
            rng.GetBytes(result)
        End Using
        Return result
    End Function

    Public Shared Function Login(username As String, password As String) As CustomerIdentity
        If username.Length > 100 OrElse password.Length > 128 Then Return Nothing
        Dim rows = Query("dbo.Customer_Credentials", P("@Username", SqlDbType.NVarChar, username, 100))
        If rows.Rows.Count = 0 Then
            HashPassword(password, New Byte(31) {}, 210000)
            Query("dbo.Customer_LogLoginFailure", P("@Username", SqlDbType.NVarChar, username, 100))
            Return Nothing
        End If
        Dim row = rows.Rows(0),
            actual = HashPassword(password, CType(row("Salt"), Byte()), CInt(row("Iterations"))),
            expected = CType(row("PasswordHash"), Byte())
        Dim difference As Integer = actual.Length Xor expected.Length
        For i = 0 To actual.Length - 1
            difference = difference Or (CInt(actual(i)) Xor CInt(expected(i)))
        Next
        Dim result = Query("dbo.Customer_LoginResult", P("@AccountID", SqlDbType.Int, row("AccountID")), P("@Stamp", SqlDbType.UniqueIdentifier, row("SecurityStamp")), P("@Success", SqlDbType.Bit, difference = 0))
        If result.Rows.Count = 0 Then
            Query("dbo.Customer_LogLoginFailure", P("@Username", SqlDbType.NVarChar, username, 100))
            Return Nothing
        End If
        Return New CustomerIdentity With {.AccountID = CInt(result.Rows(0)("AccountID")), .Name = CStr(result.Rows(0)("Name_AR")), .Stamp = CType(result.Rows(0)("SecurityStamp"), Guid)}
    End Function
    Public Shared Function ErrorText(ex As Exception) As String
        Return CustomerPortalPresentation.ErrorText(ex)
    End Function

    Public Shared Sub BindOptions(list As DropDownList, rows As DataTable,
                                  Optional hint As String = "اختر")
        CustomerPortalPresentation.BindOptions(list, rows, hint)
    End Sub
End Class



