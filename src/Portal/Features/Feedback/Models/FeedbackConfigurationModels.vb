Imports System.Linq
Imports System.Xml.Linq
Imports Prosto_ERP_ClassLibrary

Public Class FeedbackPermission
    Public Property UserTypeID As Integer
    Public Property Title As String
    Public Property CanSubmit As Boolean
    Public Property CanTransfer As Boolean
    Public Property CanClose As Boolean
    Public Property RowVersion As Byte()
    Public Property Targets As String
End Class
Public Class FeedbackTargetType
    Public Property ID As Integer
    Public Property Title As String
End Class
Public Class FeedbackLog
    Public Property Request_ID As Integer
    Public Property EventDate As DateTime
    Public Property EventType As String
    Public Property ActorName As String
End Class
Public Class FeedbackStatistic
    Public Property Dimension As String
    Public Property Value As Integer
    Public Property Label As String
    Public Property Total As Integer
End Class
Public Class FeedbackRequestRow
    Public Property SourceType As Integer
    Public Property ID As Integer
    Public Property Type As Integer
    Public Property Title As String
    Public Property Status As Integer
    Public Property AddedDate As DateTime
    Public Property CloseDate As DateTime?
    Public Property EmployeeName As String
    Public Property BranchName As String
    Public Property BrandName As String
    Public Property CurrentRecipient As String
    Public Property UnreadCount As Integer
End Class
