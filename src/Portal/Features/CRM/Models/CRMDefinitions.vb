

Public Class CRMField
    Public Property Name As String
    Public Property Label As String
    Public Property Kind As String
    Public Property MaxLength As Integer

    Public Sub New(name As String, label As String, kind As String, length As Integer)
        Me.Name = name
        Me.Label = label
        Me.Kind = kind
        Me.MaxLength = length
    End Sub
End Class

Public Class CRMDefinition
    Public Property Title As String
    Public Property Fields As List(Of CRMField)

    Public Sub New(title As String, fields As CRMField())
        Me.Title = title
        Me.Fields = New List(Of CRMField)(fields)
    End Sub
End Class


