Imports System.Data.SqlClient
Imports System.IO
Imports System.IO.Compression
Imports System.Web
Imports System.Xml.Linq
Imports System.Linq

Public Enum CorrespondenceStatus
    Active = 1
    Overdue = 2
    Closed = 3
End Enum

Public NotInheritable Class CorrespondenceData
    Public Shared Function P(name As String, type As System.Data.SqlDbType, value As Object, Optional size As Integer = 0) As SqlParameter
        Return WorkGuideAccess.Parameter(name, type, value, size)
    End Function
    Public Shared Function Query(procedure As String, ParamArray parameters As SqlParameter()) As System.Data.DataTable
        Return WorkGuideAccess.Query(procedure, parameters)
    End Function
    Public Shared Function Catalog(actor As Integer, kind As String, Optional mode As Integer = 0, Optional task As Boolean = True) As System.Data.DataTable
        Return Query("dbo.Correspondence_CatalogList", P("@Actor", System.Data.SqlDbType.Int, actor), P("@Kind", System.Data.SqlDbType.Char, kind, 1), P("@Mode", System.Data.SqlDbType.Int, mode), P("@Task", System.Data.SqlDbType.Bit, task))
    End Function
    Public Shared Function ThreadQuery(procedure As String, actor As Integer, thread As Integer) As System.Data.DataTable
        Return Query(procedure, P("@Actor", System.Data.SqlDbType.Int, actor), P("@ThreadID", System.Data.SqlDbType.Int, thread))
    End Function
    Public Shared Function KindText(value As Object) As String
        Return CorrespondencePresentation.KindText(value)
    End Function
    Public Shared Sub FillCatalog(list As System.Web.UI.WebControls.DropDownList, actor As Integer, kind As String, Optional mode As Integer = 0, Optional task As Boolean = True)
        CorrespondencePresentation.FillCatalog(list, actor, kind, mode, task)
    End Sub
    Public Shared Function StateText(value As Object) As String
        Return CorrespondencePresentation.StateText(value)
    End Function
    Public Shared Function StateCss(value As Object) As String
        Return CorrespondencePresentation.StateCss(value)
    End Function
    Public Const MaxFiles As Integer = CorrespondenceAttachments.MaxFiles
    Public Const MaxFileBytes As Integer = CorrespondenceAttachments.MaxFileBytes
    Public Shared Function StatusValue(due As Object, closed As Object) As CorrespondenceStatus
        If closed IsNot Nothing AndAlso Not IsDBNull(closed) Then Return CorrespondenceStatus.Closed
        If due IsNot Nothing AndAlso Not IsDBNull(due) AndAlso CDate(due) < DateTime.UtcNow Then Return CorrespondenceStatus.Overdue
        Return CorrespondenceStatus.Active
    End Function
    Public Shared Function StatusText(due As Object, closed As Object) As String
        Return CorrespondencePresentation.StatusText(due, closed)
    End Function
    Public Shared Function StatusCss(due As Object, closed As Object) As String
        Return CorrespondencePresentation.StatusCss(due, closed)
    End Function
    Public Shared Function DisplayDate(value As Object) As String
        Return CorrespondencePresentation.DisplayDate(value)
    End Function
    Public Shared Function MessageHtml(value As Object) As String
        Return CorrespondencePresentation.MessageHtml(value)
    End Function
    Public Shared Function SaveQueuedAttachments(items As List(Of FileAttribute), saved As List(Of String)) As XElement
        Return CorrespondenceAttachments.SaveQueuedAttachments(items, saved)
    End Function
    Public Shared Function Utc(value As Object) As String
        Return CorrespondencePresentation.Utc(value)
    End Function
    Public Shared Function Avatar(value As Object) As String
        Return CorrespondencePresentation.Avatar(value)
    End Function
    Public Shared Function FileUrl(value As Object) As String
        Return CorrespondencePresentation.FileUrl(value)
    End Function
    Public Shared Function ErrorText(ex As Exception) As String
        Return CorrespondencePresentation.ErrorText(ex)
    End Function
    Public Shared Function SaveAttachments(uploads As IEnumerable(Of HttpPostedFile), saved As List(Of String)) As XElement
        Return CorrespondenceAttachments.SaveAttachments(uploads, saved)
    End Function
    Public Shared Sub Cleanup(saved As IEnumerable(Of String))
        CorrespondenceAttachments.Cleanup(saved)
    End Sub


End Class
