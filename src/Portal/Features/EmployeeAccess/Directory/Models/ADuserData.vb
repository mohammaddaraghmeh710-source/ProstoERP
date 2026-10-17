
<Serializable>
Public Class ADuserData
    Inherits BusinessClass(Of ADuserData)

    Private _ADusersData As List(Of ADuserData)

    Public Overrides Property BusinessClassList As List(Of ADuserData)
        Get
            Return _ADusersData
        End Get
        Set
            _ADusersData = value
        End Set
    End Property

    Private _PID As Integer

    Public Property PID As Integer
        Get
            Return _PID
        End Get
        Set
            _PID = value
        End Set
    End Property

    Private _Username As String

    Public Property Username As String
        Get
            Return _Username
        End Get
        Set
            _Username = value
        End Set
    End Property

    Private _Email As String

    Public Property Email As String
        Get
            Return _Email
        End Get
        Set
            _Email = value
        End Set
    End Property

    Private _Mobile As String

    Public Property Mobile As String
        Get
            Return _Mobile
        End Get
        Set
            _Mobile = value
        End Set
    End Property

    Private _PhoneNumber As String

    Public Property PhoneNumber As String
        Get
            Return _PhoneNumber
        End Get
        Set
            _PhoneNumber = value
        End Set
    End Property

    Private _EmployeeName As String

    Public Property EmployeeName As String
        Get
            Return _EmployeeName
        End Get
        Set
            _EmployeeName = value
        End Set
    End Property
End Class



