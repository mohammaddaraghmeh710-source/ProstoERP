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

    Public Shared Function Query(name As String, ParamArray parameters As SqlParameter()) _
        As DataTable
        Return WorkGuideAccess.Query(name, parameters)
    End Function

    Public Shared Function P(name As String, kind As SqlDbType, value As Object, Optional size As Integer = 0) _
        As SqlParameter
        Return WorkGuideAccess.Parameter(name, kind, value, size)
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
            Return Nothing
        End If
        Dim row = rows.Rows(0),
            actual = HashPassword(password, CType(row("Salt"), Byte()), CInt(row("Iterations"))),
            expected = CType(row("PasswordHash"), Byte())
        Dim difference As Integer = actual.Length Xor expected.Length
        For i = 0 To actual.Length - 1
            difference = difference Or (CInt(actual(i)) Xor CInt(expected(i)))
        Next
        Dim result = Query("dbo.Customer_LoginResult", P("@AccountID", SqlDbType.Int, row("AccountID")),
                           P("@Stamp", SqlDbType.UniqueIdentifier, row("SecurityStamp")),
                           P("@Success", SqlDbType.Bit, difference = 0))
        If result.Rows.Count = 0 Then Return Nothing
        Return _
            New CustomerIdentity _
                With {.AccountID = CInt(result.Rows(0)("AccountID")), .Name = CStr(result.Rows(0)("Name_AR")),
                    .Stamp = CType(result.Rows(0)("SecurityStamp"), Guid)}
    End Function

    Public Shared Function AdminGuide(section As String, Optional account As Integer = 0, Optional brand As Integer = 0,
                                      Optional role As Integer = 0, Optional oldRole As Integer = 0,
                                      Optional categories As String = Nothing, Optional active As Boolean = True) _
        As DataTable
        If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401, "يلزم تسجيل الدخول")
        Return _
            Query("dbo.Customer_WorkGuideAdmin", P("@Actor", SqlDbType.Int, SessionManager.GetInstance.Users.UserID),
                  P("@Section", SqlDbType.VarChar, section, 20), P("@AccountID", SqlDbType.Int, account),
                  P("@Brand", SqlDbType.Int, brand), P("@Role", SqlDbType.Int, role),
                  P("@OldRole", SqlDbType.Int, oldRole), P("@Categories", SqlDbType.Xml, categories),
                  P("@Active", SqlDbType.Bit, active))
    End Function

    Public Shared Function WorkGuide(section As String, Optional brand As Integer = 0,
                                     Optional categories As String = Nothing, Optional search As String = "",
                                     Optional reason As String = Nothing, Optional status As String = "P") As DataTable
        Return _
            CustomerQuery("dbo.Customer_WorkGuide", P("@Section", SqlDbType.VarChar, section, 20),
                          P("@Brand", SqlDbType.Int, brand), P("@Categories", SqlDbType.Xml, categories),
                          P("@Search", SqlDbType.NVarChar, search, 500), P("@Reason", SqlDbType.NVarChar, reason, 1000),
                          P("@Status", SqlDbType.Char, status, 1))
    End Function

    Public Shared Function Guide(section As String, Optional brand As Integer = 0, Optional document As Integer = 0,
                                 Optional search As String = "") As DataTable
        Return _
            CustomerQuery("dbo.Customer_Guide", P("@Section", SqlDbType.VarChar, section, 16),
                          P("@Brand", SqlDbType.Int, brand), P("@DocumentID", SqlDbType.Int, document),
                          P("@Search", SqlDbType.NVarChar, search, 200))
    End Function

    Public Shared Sub LogFile(document As Integer, action As String)
        CustomerQuery("dbo.Customer_LogDocument", P("@DocumentID", SqlDbType.Int, document),
                      P("@Action", SqlDbType.VarChar, action, 30))
    End Sub

    Public Shared Function ErrorText(ex As Exception) As String
        Return CustomerPortalPresentation.ErrorText(ex)
    End Function

    Public Shared Sub BindOptions(list As DropDownList, rows As DataTable,
                                  Optional hint As String = "اختر")
        CustomerPortalPresentation.BindOptions(list, rows, hint)
    End Sub
End Class



