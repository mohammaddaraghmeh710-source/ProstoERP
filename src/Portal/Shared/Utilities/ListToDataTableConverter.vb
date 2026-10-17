
Imports System.Reflection

<Serializable>
Public Class ListToDataTableConverter (Of T)

    Private _ListToConvert As List(Of T)
    Private _PropertiesNames As List(Of String)
    Private _ListType As AppSettings.ExportableLists = Nothing
    Private _selectedColumnsNames As List(Of String)
    Private _selectedColumnsTexts As List(Of String)
    Private _dt As New DataTable

    Public Property ListToConvert As List(Of T)
        Get
            Return _ListToConvert
        End Get
        Set
            _ListToConvert = value
        End Set
    End Property

    Public Sub SetDataTablevalues(ListtoConvert As List(Of T), wantedColumnsNames As List(Of String),
                                  columnsHeadersText As List(Of String))
        _ListToConvert = ListToConvert
        _selectedColumnsNames = wantedColumnsNames
        setPropertiesNames()
        _selectedColumnsTexts = columnsHeadersText

        If Not _PropertiesNames Is Nothing Then
            Dim index = 0
            For Each columnName As String In _PropertiesNames
                If _selectedColumnsNames.Contains(columnName) Then
                    Dim column As New DataColumn(columnName)
                    column.Caption = _selectedColumnsTexts.Item(index)
                    _dt.Columns.Add(column)
                    index += 1
                End If
            Next
        End If
    End Sub

    Private Sub setPropertiesNames()
        If Not _ListToConvert Is Nothing Then
            Dim type As Type = GetType(T)
            Dim propertiesInfo As PropertyInfo() = type.GetProperties()
            _PropertiesNames = New List(Of String)
            For Each Prop As PropertyInfo In propertiesInfo
                '   If Prop.PropertyType.ToString().ToLower().Contains("string") Then
                _PropertiesNames.Add(Prop.Name)
                'ElseIf Prop.PropertyType.ToString().ToLower().Contains("int32") Then
                '_PropertiesNames.Add(Prop.Name)

                'ElseIf Prop.PropertyType.ToString().ToLower().Contains("int16") Then
                '_PropertiesNames.Add(Prop.Name)

                'ElseIf Prop.PropertyType.ToString().ToLower().Contains("object") Then
                '_PropertiesNames.Add(Prop.Name)

                'ElseIf Prop.PropertyType.ToString().ToLower().Contains("datetime") Then
                '_PropertiesNames.Add(Prop.Name)

                'ElseIf Prop.PropertyType.ToString().ToLower().Contains("boolean") Then
                '_PropertiesNames.Add(Prop.Name)
                'End If
            Next
        End If
    End Sub

    Public Function getDatatable() As DataTable
        Return _dt
    End Function
End Class


