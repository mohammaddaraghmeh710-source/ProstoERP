Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Web
Imports System.Xml.Linq

Public NotInheritable Class CRMData
    Public Shared Function P(name As String, type As SqlDbType, value As Object, Optional size As Integer = 0) As SqlParameter
        Return PortalSqlData.Parameter(name, type, value, size)
    End Function

    Public Shared Function Query(procedure As String, ParamArray values As SqlParameter()) As DataTable
        Return PortalSqlData.Query(procedure, values)
    End Function

    Public Shared Function Rows(entity As String, actor As Integer, Optional id As Integer = 0) As DataTable
        If Not CRMModel.Entities.ContainsKey(entity) Then Throw New InvalidOperationException("نوع السجل غير صحيح.")
        Return Query("dbo.CRM_Select_" & entity, P("@Actor_ID", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, If(id = 0, CType(Nothing, Object), id)))
    End Function

    Public Shared Function Save(entity As String, actor As Integer, id As Integer, data As XElement, version As Byte()) As DataTable
        If Not CRMModel.Entities.ContainsKey(entity) Then Throw New InvalidOperationException("نوع السجل غير صحيح.")
        Return Query("dbo.CRM_Save_" & entity, P("@Actor_ID", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, id), P("@Data", SqlDbType.Xml, data.ToString()), P("@Version", SqlDbType.Binary, version, 8))
    End Function

    ' Both existing procedures participate in one local SQL transaction; no partial profile save.
    Public Shared Sub SaveAccountProfile(actor As Integer, id As Integer, data As XElement, version As Byte(), username As String, password As String, loginActive As Boolean, loginVersion As Byte(), saveLogin As Boolean, Optional logo As Byte() = Nothing)
        Dim salt As Byte() = Nothing, hash As Byte() = Nothing
        If saveLogin AndAlso password <> "" Then
            If password.Length < 8 OrElse password.Length > 128 Then Throw New InvalidOperationException("كلمة المرور من 8 إلى 128 حرفًا.")
            salt = CustomerPortalData.NewSalt()
            hash = CustomerPortalData.HashPassword(password, salt, 210000)
        End If
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            Dim connection = DirectCast(db.Connection, SqlConnection)
            connection.Open()
            Using transaction = connection.BeginTransaction()
                Dim stagedLogo As String = Nothing
                Try
                    stagedLogo = CRMAccountLogo.SaveFile(logo)
                    Using command As New SqlCommand("dbo.CRM_Save_Accounts", connection, transaction)
                        command.CommandType = CommandType.StoredProcedure
                        command.Parameters.AddRange({P("@Actor_ID", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, id), P("@Data", SqlDbType.Xml, data.ToString()), P("@Version", SqlDbType.Binary, version, 8)})
                        Dim result As New DataTable()
                        Using adapter As New SqlDataAdapter(command)
                            adapter.Fill(result)
                        End Using
                        id = CInt(result.Rows(0)("ID"))
                        version = DirectCast(result.Rows(0)("Row_Version"), Byte())
                    End Using
                    If logo IsNot Nothing Then
                        Using command As New SqlCommand("dbo.CRM_Save_Account_Logo", connection, transaction)
                            command.CommandType = CommandType.StoredProcedure
                            command.Parameters.AddRange({P("@Actor_ID", SqlDbType.Int, actor), P("@Account_ID", SqlDbType.Int, id), P("@Logo_Url", SqlDbType.NVarChar, stagedLogo, 260), P("@Version", SqlDbType.Binary, version, 8)})
                            command.ExecuteNonQuery()
                        End Using
                    End If
                    If saveLogin Then
                        Using command As New SqlCommand("dbo.Customer_SaveLogin", connection, transaction)
                            command.CommandType = CommandType.StoredProcedure
                            command.Parameters.AddRange({P("@Actor", SqlDbType.Int, actor), P("@AccountID", SqlDbType.Int, id), P("@Username", SqlDbType.NVarChar, username, 100), P("@Hash", SqlDbType.VarBinary, hash, 32), P("@Salt", SqlDbType.VarBinary, salt, 32), P("@Active", SqlDbType.Bit, loginActive), P("@Version", SqlDbType.Binary, loginVersion, 8)})
                            command.ExecuteNonQuery()
                        End Using
                    End If
                    transaction.Commit()
                Catch
                    If transaction.Connection IsNot Nothing Then transaction.Rollback()
                    CRMAccountLogo.RemoveStagedFile(stagedLogo)
                    Throw
                End Try
            End Using
        End Using
    End Sub

    Public Shared Function H(value As Object) As String
        Return HttpUtility.HtmlEncode(Convert.ToString(value, CultureInfo.InvariantCulture))
    End Function

    Public Shared Function Link(entity As String, Optional mode As String = "Manage", Optional id As Integer = 0) As String
        Dim page = mode & "CRM" & entity.Replace("_", "") & ".aspx"
        Return "/Modules/CRM_" & entity & "/" & page & If(id = 0, "", "?id=" & id.ToString(CultureInfo.InvariantCulture))
    End Function

    Public Shared Function ErrorMessage(ex As Exception) As String
        System.Diagnostics.Trace.TraceError("CRM: {0}", ex.ToString())
        Dim sql = TryCast(ex, SqlException)
        If sql IsNot Nothing Then
            If sql.Number = 51200 OrElse sql.Number = 51201 Then Return sql.Message
            If sql.Number = 2601 OrElse sql.Number = 2627 Then Return "الاسم أو رقم تسجيل العميل مستخدم مسبقًا."
        End If
        If TypeOf ex Is InvalidOperationException Then Return ex.Message
        Return "تعذّر تنفيذ العملية. أعد المحاولة أو راجع مدير النظام."
    End Function
End Class

Public Class CRMField
    Public Property Name As String
    Public Property Label As String
    Public Property Kind As String
    Public Property MaxLength As Integer
    Public Sub New(name As String, label As String, kind As String, length As Integer)
        Me.Name = name : Me.Label = label : Me.Kind = kind : Me.MaxLength = length
    End Sub
End Class

Public Class CRMDefinition
    Public Property Title As String
    Public Property Fields As List(Of CRMField)
    Public Sub New(title As String, fields As CRMField())
        Me.Title = title : Me.Fields = New List(Of CRMField)(fields)
    End Sub
End Class
