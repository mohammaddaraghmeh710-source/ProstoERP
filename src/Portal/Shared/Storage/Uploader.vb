Imports System.Runtime.CompilerServices
Imports CRM
'Imports Microsoft.AspNet.Identity

Public Module Uploader
    'Dim _passwordHasher As PasswordHasher
    'Sub New()

    '    _passwordHasher = New PasswordHasher()
    'End Sub
    Public Const BlogFilePath = "/FileManager/"

    Public ReadOnly Property BlogUrl As String
        Get
            Return HttpContext.Current.Request.Url.Authority
        End Get
    End Property

    Public ReadOnly Property BlogUserPrefixUrl As String
        Get
            Return BlogUrl + "/FileManager/"
        End Get
    End Property


    <Extension>
    Public Function GetBlogStatusString(status As Integer?) As String
        Try
            If status.HasValue Then
                Return status.Value.GetBlogStatusString()
            End If
            Return String.Empty
        Catch
            Return String.Empty
        End Try
    End Function

    <Extension>
    Public Function GetBlogStatusString(status As Integer) As String
        Try

            If status = BlogStatus.Pending Then
                Return "Pending"
            ElseIf status = BlogStatus.Approved Then
                Return "Approved"
            ElseIf status = BlogStatus.Disapproved Then
                Return "Disapproved"
            ElseIf status = BlogStatus.Draft Then
                Return "Draft"

            End If
            Return String.Empty
        Catch
            Return String.Empty
        End Try
    End Function
End Module


Public Class FileAttribute
    Property Type As String
    Property FileByte As Byte()
    Property NameFile As String
End Class

Public Class FileEnglishAttribute
    Property Type As String
    Property FileByte As Byte()
    Property NameFile As String
End Class


Public Class InspectionMethodVideoAttribute
    Property Type As String
    Property FileByte As Byte()
    Property NameFile As String
End Class


Public Class Power_Generation_Materials
    Property MaterialsID As Int32
    Property MaterialName As String
    Property Model As String
    Property Unit As String
    Property Quantity As Int32
End Class

Public Class IntegratedSystems_Materials
    Property MaterialsID As Int32
    Property MaterialName As String
    Property Model As String
    Property Unit As String
    Property Quantity As Int32
    Property Price As Double
End Class


Public Class ManufacturingEquation_Items
    Property RefID As Int32
    Property Identification_Number As String
    Property Item_Description As String
    Property Model As String
    Property Description As String
    Property Unit As String
    Property Quantity As Int32
End Class


Public Enum BlogStatus
    Pending = 1
    Approved = 2
    Disapproved = 3
    Draft = 4
End Enum


Public Class Uplod
    Public Sub New()
        Id2 = Guid.NewGuid().ToString()
        _state = StateUplod.Unchanged
    End Sub

    Dim _state As StateUplod
    Public Property Id2 As String
    Public Property Pid2 As Integer

    Public Property FileName As String
    Public Property filePath As String


    Public Property State As StateUplod
        Get
            Return _state
        End Get
        Set
            If value = StateUplod.Added Then
                _state = StateUplod.Added
            ElseIf value = StateUplod.Modified Then

                If Pid2 = 0 Then
                    _state = StateUplod.Added
                Else
                    _state = StateUplod.Modified
                End If

            ElseIf value = StateUplod.Deleted Then
                If Pid2 > 0 Then
                    _state = StateUplod.Deleted
                Else
                    _state = StateUplod.Removed
                End If

            Else
                _state = value
            End If
        End Set
    End Property

    Public Sub Delete()
        State = StateUplod.Deleted
    End Sub

    Public ReadOnly Property Visible1 As Boolean
        Get
            Return State <> StateUplod.Deleted And State <> StateUplod.Removed
        End Get
    End Property
End Class

Public Enum StateUplod
    Unchanged = 0
    Added = 1
    Modified = 2
    Deleted = 3
    Removed = 4
End Enum

Public Class AttacmentFile
    Property Name As String
    Property Type As String
    Property FileByte As Byte()
    Property FillPath As String
End Class



