Imports System.Data.SqlClient
Imports System.IO
Imports System.IO.Compression
Imports System.Web
Imports System.Xml.Linq
Imports System.Linq

Public NotInheritable Class EmployeeFeedbackData
    Public Const MaxFiles As Integer = EmployeeFeedbackAttachments.MaxFiles
    Public Const MaxFileBytes As Integer = EmployeeFeedbackAttachments.MaxFileBytes
    Public Const SubmitAction As Integer = 1
    Public Const TransferAction As Integer = 2
    Public Const CloseAction As Integer = 3
    Public Shared Function LogDate(value As Object) As String
        Return FeedbackPresentation.LogDate(value)
    End Function
    Public Shared Function StatusText(value As Object) As String
        Return FeedbackPresentation.StatusText(value)
    End Function
    Public Shared Function StatusCss(value As Object) As String
        Return FeedbackPresentation.StatusCss(value)
    End Function
    Public Shared Function ActionText(value As Object) As String
        Return FeedbackPresentation.ActionText(value)
    End Function
    Public Shared Function TypeText(value As Object) As String
        Return FeedbackPresentation.TypeText(value)
    End Function
    Public Shared Function ErrorText(ex As Exception) As String
        Return FeedbackPresentation.ErrorText(ex)
    End Function
    Public Shared Function SaveQueuedAttachments(items As List(Of FileAttribute), saved As List(Of String)) As XElement
        Return EmployeeFeedbackAttachments.SaveQueuedAttachments(items, saved)
    End Function

End Class
