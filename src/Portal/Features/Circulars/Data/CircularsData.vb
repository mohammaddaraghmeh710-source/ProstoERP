Imports System.Data.SqlClient

Public NotInheritable Class CircularsData
    Public Shared Function Query(name As String, ParamArray parameters() As SqlParameter) As DataSet
        Using _
            cn As _
                New SqlConnection(
                    ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").
                                     ConnectionString),
            cmd As New SqlCommand(name, cn), adapter As New SqlDataAdapter(cmd)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddRange(parameters)
            Dim result As New DataSet()
            adapter.Fill(result)
            Return result
        End Using
    End Function

    Public Shared Function P(name As String, kind As SqlDbType, value As Object, Optional size As Integer = 0) _
        As SqlParameter
        Return InformationPagesData.P(name, kind, value, size)
    End Function

    Public Shared Function Label(value As Object) As String
        Return CircularsPresentation.Label(value)
    End Function

    Public Shared Function ErrorText(ex As Exception) As String
        Return CircularsPresentation.ErrorText(ex)
    End Function

    Public Shared Function Pdf(file As HttpPostedFile) As Byte()
        Return CircularsDocuments.Pdf(file)
    End Function
End Class



