Imports Newtonsoft.Json

Public Class RememberMeToken
    Private Const HoursValidity As Integer = 240

    Public Sub New(user As UserEntity)
        If user Is Nothing Then
            Throw New ArgumentNullException("User")
        End If

        UserId = user.UserID
        UserName = user.Username
        CreateDate = DateTime.Now
    End Sub

    Public Sub New()
    End Sub

    Public Property UserId() As Integer
        Get
            Return m_UserId
        End Get
        Set(value As Integer)
            m_UserId = value
        End Set
    End Property
    Private m_UserId As Integer

    Public Property UserName() As String
        Get
            Return m_UserName
        End Get
        Set(value As String)
            m_UserName = value
        End Set
    End Property
    Private m_UserName As String

    Public Property CreateDate() As DateTime
        Get
            Return m_CreateDate
        End Get
        Set(value As DateTime)
            m_CreateDate = value
        End Set
    End Property
    Private m_CreateDate As DateTime

    Public Function IsValid() As Boolean
        Return CreateDate.AddHours(HoursValidity) >= DateTime.Now
    End Function
End Class

Public Class RememberMeTokenProvider
    Public Shared Function GetTokenString(token As RememberMeToken) As String
        Dim tokenString As String = JsonConvert.SerializeObject(token)
        tokenString = EncryptDecrypt.Encrypt(tokenString)
        Return tokenString
    End Function

    Public Shared Function GetTokenFromString(tokenString As String) As RememberMeToken
        Try
            tokenString = EncryptDecrypt.Decrypt(tokenString)
            If String.IsNullOrEmpty(tokenString) Then
                Return Nothing
            End If

            Dim token As RememberMeToken = JsonConvert.DeserializeObject(Of RememberMeToken)(tokenString)
            Return token
        Catch
            Return Nothing
        End Try
    End Function


End Class
