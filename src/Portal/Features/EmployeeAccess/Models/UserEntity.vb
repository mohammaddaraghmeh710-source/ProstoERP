<Serializable()> _
Public Class UserEntity

    Private _UserID As Int32
    Public Property UserID() As Integer
        Get
            Return _UserID
        End Get
        Set(value As Integer)
            _UserID = value
        End Set
    End Property

    Private _Username As String
    Public Property Username() As String
        Get
            Return _Username
        End Get
        Set(value As String)
            _Username = value
        End Set
    End Property

    Private _Password As String
    Public Property Password() As String
        Get
            Return _Password
        End Get
        Set(value As String)
            _Password = value
        End Set
    End Property

    Private _Email As String
    Public Property Email() As String
        Get
            Return _Email
        End Get
        Set(value As String)
            _Email = value
        End Set
    End Property

    Private _PhoneNumber As String
    Public Property PhoneNumber() As String
        Get
            Return _PhoneNumber
        End Get
        Set(value As String)
            _PhoneNumber = value
        End Set
    End Property

    Private _RegisterationDate As DateTime
    Public Property RegisterationDate() As DateTime
        Get
            Return _RegisterationDate
        End Get
        Set(value As DateTime)
            _RegisterationDate = value
        End Set
    End Property

    Private _LastLoginDate As DateTime
    Public Property LastLoginDate() As DateTime
        Get
            Return _LastLoginDate
        End Get
        Set(value As DateTime)
            _LastLoginDate = value
        End Set
    End Property

    Private _UserImage As String
    Public Property UserImage() As String
        Get
            Return _UserImage
        End Get
        Set(value As String)
            _UserImage = value
        End Set
    End Property

    Private _IsPublisher As Boolean
    Public Property IsPublisher() As Boolean
        Get
            Return _IsPublisher
        End Get
        Set(value As Boolean)
            _IsPublisher = value
        End Set
    End Property

    Private _IsAdmin As Boolean
    Public Property IsAdmin() As Boolean
        Get
            Return _IsAdmin
        End Get
        Set(value As Boolean)
            _IsAdmin = value
        End Set
    End Property

    Private _NameAr As String
    Public Property NameAr() As String
        Get
            Return _NameAr
        End Get
        Set(value As String)
            _NameAr = value
        End Set
    End Property

    Private _NameEn As String
    Public Property NameEn() As String
        Get
            Return _NameEn
        End Get
        Set(value As String)
            _NameEn = value
        End Set
    End Property

    Private _UserType As Int32
    Public Property UserType() As Integer
        Get
            Return _UserType
        End Get
        Set(value As Integer)
            _UserType = value
        End Set
    End Property

    Private _IsDeleted As Boolean
    Public Property IsDeleted() As Boolean
        Get
            Return _IsDeleted
        End Get
        Set(value As Boolean)
            _IsDeleted = value
        End Set
    End Property

    Private _GroupID As Int32
    Public Property GroupID() As Int32
        Get
            Return _GroupID
        End Get
        Set(value As Int32)
            _GroupID = value
        End Set
    End Property



    Private _Gender As Int32
    Public Property Gender() As Int32
        Get
            Return _Gender
        End Get
        Set(value As Int32)
            _Gender = value
        End Set
    End Property

End Class

