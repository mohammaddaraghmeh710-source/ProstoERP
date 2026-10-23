Imports System.Web.UI

Public Class CircularReader
    Inherits UserControl

    Private modeValue As String = "employee"
    Public Property Mode As String
        Get
            Return modeValue
        End Get
        Set(value As String)
            If value <> "customer" AndAlso value <> "employee" AndAlso value <> "admin" Then Throw New ArgumentException("Invalid circular reader mode.")
            modeValue = value
        End Set
    End Property
    Protected ReadOnly Property ReaderMode As String
        Get
            Return Mode
        End Get
    End Property
    Public Property InitialID As Integer
    Public ReadOnly Property CurrentToken As String
        Get
            Dim key = If(Mode = "customer", "CustomerCircularCsrf", "CircularCsrf")
            If Session(key) Is Nothing Then Session(key) = Guid.NewGuid().ToString("N")
            Return CStr(Session(key))
        End Get
    End Property
End Class
