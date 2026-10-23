Imports System.Data
Imports System.Data.SqlClient

Public NotInheritable Class PortalSqlData
    Private Sub New()
    End Sub

    Public Shared Function Parameter(name As String, type As SqlDbType, value As Object, Optional size As Integer = 0) As SqlParameter
        Dim item As New SqlParameter(name, type)
        If size <> 0 Then item.Size = size
        item.Value = If(value, DBNull.Value)
        Return item
    End Function

    Public Shared Function Query(procedure As String, ParamArray parameters As SqlParameter()) As DataTable
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            Using command As New SqlCommand(procedure, DirectCast(db.Connection, SqlConnection))
                command.CommandType = CommandType.StoredProcedure
                command.Parameters.AddRange(parameters)
                Using adapter As New SqlDataAdapter(command)
                    Dim result As New DataTable()
                    adapter.Fill(result)
                    Return result
                End Using
            End Using
        End Using
    End Function

End Class
