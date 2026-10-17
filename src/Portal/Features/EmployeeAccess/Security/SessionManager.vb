

Public Class SessionManager
    Private Const _PrintedDataTable As String = "PrintedDataTable"
    Private Const _ExcelFileTitle As String = "ExcelFileTitle"
    Private Const _ColumnsTitles As String = "ColumnsTitles"

    Private Const _UserObject As String = "UserSessionObject"

    Private Shared _current As New SessionManager()

    Public Shared ReadOnly Property GetInstance As SessionManager
        Get
            If _current IsNot Nothing Then
                Return _current
            Else
                _current = New SessionManager()
                Return _current
            End If
        End Get
    End Property

    Public Property Users As UserEntity
        Get
            Dim context = HttpContext.Current
            Dim user = DirectCast(context.Session(_UserObject), UserEntity)
            If user Is Nothing Then Return Nothing
            Dim cacheKey = "EmployeeResetChecked:" & user.UserID.ToString()
            If context.Items(cacheKey) Is Nothing Then
                Try
                    Dim current = EmployeeSessionResetGuard.Read(user.UserID)
                    Dim epoch =
                            If _
                            (context.Session("EmployeeResetEpoch") Is Nothing, 0L,
                             CLng(context.Session("EmployeeResetEpoch")))
                    If _
                        current Is Nothing OrElse current.Epoch <> epoch OrElse
                        (Not String.IsNullOrEmpty(user.Password) AndAlso
                         Not String.Equals(user.Password, current.Password, StringComparison.Ordinal)) Then
                        context.Session.Remove(_UserObject)
                        context.Session.Remove("LogIn")
                        Return Nothing
                    End If
                    context.Items(cacheKey) = True
                Catch
                    context.Session.Remove(_UserObject)
                    context.Session.Remove("LogIn")
                    Return Nothing
                End Try
            End If
            Return user
        End Get
        Set
            HttpContext.Current.Session(_UserObject) = value
            If value Is Nothing Then
                HttpContext.Current.Session.Remove("EmployeeResetEpoch")
            Else
                Dim current = EmployeeSessionResetGuard.Read(value.UserID)
                HttpContext.Current.Session("EmployeeResetEpoch") =
                    If(current Is Nothing, - 1L, current.Epoch)
                HttpContext.Current.Items.Remove("EmployeeResetChecked:" & value.UserID.ToString())
            End If
        End Set
    End Property

    Public Property PrintedDataTable As DataTable
        Get
            Return HttpContext.Current.Session(_PrintedDataTable)
        End Get
        Set
            HttpContext.Current.Session(_PrintedDataTable) = value
        End Set
    End Property

    Public Property ExcelFileTitle As String
        Get
            Return HttpContext.Current.Session(_ExcelFileTitle)
        End Get
        Set
            HttpContext.Current.Session(_ExcelFileTitle) = value
        End Set
    End Property

    Public Property TableColumnsTitles As List(Of String)
        Get
            Return HttpContext.Current.Session(_ColumnsTitles)
        End Get
        Set
            HttpContext.Current.Session(_ColumnsTitles) = value
        End Set
    End Property
End Class


