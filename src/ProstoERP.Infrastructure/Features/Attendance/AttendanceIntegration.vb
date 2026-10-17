Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text

' Shared by Portal, attendance and brand email APIs; DPAPI blobs can be decrypted only on the Portal Windows host that saved them.
Public NotInheritable Class AttendanceIntegration
    Private ReadOnly connection As String

    Public Sub New(connectionString As String)
        connection = connectionString
    End Sub

    Public Function Query(procedure As String, ParamArray parameters As SqlParameter()) As DataTable
        Using cn As New SqlConnection(connection), cmd As New SqlCommand(procedure, cn),
            adapter As New SqlDataAdapter(cmd)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddRange(parameters)
            Dim table As New DataTable()
            adapter.Fill(table)
            Return table
        End Using
    End Function

    Public Shared Function Protect(value As String) As Byte()
        Return _
            ProtectedData.Protect(Encoding.UTF8.GetBytes(value), Encoding.UTF8.GetBytes("ERPProsto.Attendance.v1"),
                                  DataProtectionScope.LocalMachine)
    End Function

    Public Shared Function Unprotect(value As Byte()) As String
        Return _
            Encoding.UTF8.GetString(ProtectedData.Unprotect(value, Encoding.UTF8.GetBytes("ERPProsto.Attendance.v1"),
                                                            DataProtectionScope.LocalMachine))
    End Function

    Public Shared Function PasswordHash(password As String, salt As Byte()) As Byte()
        Using derive As New Rfc2898DeriveBytes(password, salt, 150000, HashAlgorithmName.SHA256)
            Return derive.GetBytes(32)
        End Using
    End Function

    Public Shared Function Matches(password As String, salt As Byte(), expected As Byte()) As Boolean
        Dim actual = PasswordHash(password, salt)
        Dim different As Integer = actual.Length Xor expected.Length
        For i = 0 To Math.Min(actual.Length, expected.Length) - 1
            different = different Or (CInt(actual(i)) Xor CInt(expected(i)))
        Next
        Return different = 0
    End Function

    Public Function Authenticate(username As String, password As String) As Integer
        Dim data = Query("dbo.AttendanceIntegration_Authenticate",
                         New SqlParameter("@ApiUsername", SqlDbType.NVarChar, 200) With {.Value = username})
        ' The procedure returns -1 only when no brand configuration exists (legacy compatibility).
        If data.Rows.Count = 1 AndAlso CInt(data.Rows(0)("BrandID")) = - 1 Then Return - 1
        If data.Rows.Count <> 1 Then Return 0
        Dim row = data.Rows(0)
        If Not Matches(password, DirectCast(row("ApiSalt"), Byte()), DirectCast(row("ApiHash"), Byte())) Then Return 0
        Return CInt(row("BrandID"))
    End Function

    Public Function Metadata(actor As Integer, brand As Integer) As DataTable
        Return _
            Query("dbo.AttendanceIntegration_Admin", New SqlParameter("@Actor", actor),
                  New SqlParameter("@BrandID", brand))
    End Function

    Public Sub Save(actor As Integer, brand As Integer, username As String, apiPassword As String, bioUsername As String,
                    bioPassword As String, enabled As Boolean, version As Byte(), Optional apiUrl As String = Nothing,
                    Optional bioTimeUrl As String = Nothing, Optional hrUrl As String = Nothing,
                    Optional hrUsername As String = Nothing, Optional hrPassword As String = Nothing)
        If _
            String.IsNullOrWhiteSpace(username) OrElse username.Contains(":") OrElse username.Length > 200 OrElse
            String.IsNullOrWhiteSpace(bioUsername) OrElse bioUsername.Length > 200 OrElse apiPassword.Length > 1000 OrElse
            bioPassword.Length > 1000 Then Throw New ArgumentException("Invalid settings.")
        If apiUrl IsNot Nothing Then apiUrl = NormalizeUrl(apiUrl)
        If bioTimeUrl IsNot Nothing Then bioTimeUrl = NormalizeUrl(bioTimeUrl, True)
        If hrUrl IsNot Nothing AndAlso hrUrl.Length > 0 Then
            hrUrl = NormalizeUrl(hrUrl)
            If _
                String.IsNullOrWhiteSpace(hrUsername) OrElse hrUsername.Length > 200 OrElse
                (hrPassword IsNot Nothing AndAlso hrPassword.Length > 1000) Then _
                Throw New ArgumentException("Invalid HR settings.")
            Dim existing = Metadata(actor, brand)
            If _
                (existing.Rows.Count = 0 OrElse Not CBool(existing.Rows(0)("HasHrPassword"))) AndAlso
                String.IsNullOrWhiteSpace(hrPassword) Then Throw New ArgumentException("HR password required.")
        End If
        Dim salt(31) As Byte
        If apiPassword.Length > 0 Then
            Using random = RandomNumberGenerator.Create()
                random.GetBytes(salt)
            End Using
        End If
        Query("dbo.AttendanceIntegration_Save", New SqlParameter("@Actor", actor), New SqlParameter("@BrandID", brand),
              New SqlParameter("@ApiUsername", SqlDbType.NVarChar, 200) With {.Value = username},
              New SqlParameter("@ApiPassword", SqlDbType.VarBinary, - 1) _
                 With {.Value = If(apiPassword.Length = 0, CType(DBNull.Value, Object), Protect(apiPassword))},
              New SqlParameter("@ApiSalt", SqlDbType.Binary, 32) _
                 With {.Value = If(apiPassword.Length = 0, CType(DBNull.Value, Object), salt)},
              New SqlParameter("@ApiHash", SqlDbType.Binary, 32) _
                 With {.Value = If(apiPassword.Length = 0, CType(DBNull.Value, Object), PasswordHash(apiPassword, salt))
                 },
              New SqlParameter("@BioUsername", SqlDbType.VarBinary, - 1) With {.Value = Protect(bioUsername)},
              New SqlParameter("@BioPassword", SqlDbType.VarBinary, - 1) _
                 With {.Value = If(bioPassword.Length = 0, CType(DBNull.Value, Object), Protect(bioPassword))},
              New SqlParameter("@ApiUrl", SqlDbType.NVarChar, 2000) _
                 With {.Value = If(apiUrl Is Nothing, CType(DBNull.Value, Object), apiUrl)},
              New SqlParameter("@BioTimeUrl", SqlDbType.NVarChar, 2000) _
                 With {.Value = If(bioTimeUrl Is Nothing, CType(DBNull.Value, Object), bioTimeUrl)},
              New SqlParameter("@HrUrl", SqlDbType.NVarChar, 2000) _
                 With {.Value = If(hrUrl Is Nothing, CType(DBNull.Value, Object), hrUrl)},
              New SqlParameter("@HrUsername", SqlDbType.VarBinary, - 1) _
                 With { _
                 .Value = If(String.IsNullOrWhiteSpace(hrUsername), CType(DBNull.Value, Object), Protect(hrUsername))},
              New SqlParameter("@HrPassword", SqlDbType.VarBinary, - 1) _
                 With {.Value = If(String.IsNullOrEmpty(hrPassword), CType(DBNull.Value, Object), Protect(hrPassword))},
              New SqlParameter("@Enabled", enabled),
              New SqlParameter("@Version", SqlDbType.Binary, 8) _
                 With {.Value = If(version Is Nothing, CType(DBNull.Value, Object), version)})
    End Sub

    Public Shared Function NormalizeUrl(value As String, Optional rootOnly As Boolean = False) As String
        Dim target As Uri = Nothing
        If _
            value Is Nothing OrElse value.Trim().Length > 2000 OrElse
            Not Uri.TryCreate(value.Trim(), UriKind.Absolute, target) OrElse
            (target.Scheme <> "http" AndAlso target.Scheme <> "https") OrElse target.UserInfo.Length > 0 OrElse
            target.Query.Length > 0 OrElse target.Fragment.Length > 0 OrElse
            (rootOnly AndAlso target.AbsolutePath <> "/") Then Throw New ArgumentException("Invalid API URL.")
        Return target.AbsoluteUri.TrimEnd("/"c) & "/"
    End Function

    Public Function BioTimeUrl(brand As Integer) As String
        Dim rows = Query("dbo.AttendanceIntegration_BioTimeUrl", New SqlParameter("@BrandID", brand))
        If rows.Rows.Count <> 1 Then Throw New InvalidOperationException("Brand integration unavailable.")
        Return NormalizeUrl(CStr(rows.Rows(0)("BioTimeUrl")), True)
    End Function
End Class


