Imports System.Data.SqlClient
Imports Prosto_ERP_ClassLibrary

Public NotInheritable Class WorkGuideAccess
    Private Sub New()
    End Sub

    Public Shared Function Parameter(name As String, type As SqlDbType, value As Object, Optional size As Integer = 0) _
        As SqlParameter
        Dim item As New SqlParameter(name, type)
        If size <> 0 Then item.Size = size
        item.Value = If(value, DBNull.Value)
        Return item
    End Function

    Public Shared Function Query(procedure As String, ParamArray parameters As SqlParameter()) As DataTable
        Using db As New Prosto_ERP_DataClassesDataContext()
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

    Public Shared Function Categories(userID As Integer) As DataTable
        Return Query("dbo.Select_Work_Guide_Request_Categories", Parameter("@User_ID", SqlDbType.Int, userID))
    End Function

    Public Shared Function Requests(actorID As Integer, status As String, brandID As Integer?, keyword As String,
                                    batchID As Guid?, page As Integer, Optional pageSize As Integer = 50,
                                    Optional allRows As Boolean = False) As DataTable
        Return Query("dbo.Select_Work_Guide_Access_Requests",
                     Parameter("@Actor_ID", SqlDbType.Int, actorID),
                     Parameter("@Status", SqlDbType.Char, If(String.IsNullOrWhiteSpace(status), Nothing, status), 1),
                     Parameter("@Brand_ID", SqlDbType.Int, brandID),
                     Parameter("@Keyword", SqlDbType.NVarChar, keyword, 200),
                     Parameter("@Batch_ID", SqlDbType.UniqueIdentifier, batchID),
                     Parameter("@PageNumber", SqlDbType.Int, page), Parameter("@PageSize", SqlDbType.Int, pageSize),
                     Parameter("@All_Rows", SqlDbType.Bit, allRows))
    End Function

    Public Shared Function Submit(userID As Integer, categories As IEnumerable(Of Integer), reason As String) _
        As DataTable
        Dim _
            xml As _
                New XElement("items",
                             categories.Distinct().Select(Function(id) New XElement("item", New XAttribute("id", id))))
        Return Query("dbo.Insert_Work_Guide_Access_Request", Parameter("@User_ID", SqlDbType.Int, userID),
                     Parameter("@Category_IDs", SqlDbType.Xml, xml.ToString()),
                     Parameter("@Reason", SqlDbType.NVarChar, reason, 1000))
    End Function

    Public Shared Function StatusCss(value As Object) As String
        Return WorkGuidePresentation.StatusCss(value)
    End Function


    Public Shared Function StatusText(value As Object) As String
        Return WorkGuidePresentation.StatusText(value)
    End Function

    Public Shared Function ErrorText(ex As SqlException) As String
        Return WorkGuidePresentation.ErrorText(ex)
    End Function
End Class


