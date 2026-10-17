Imports System.IO
Imports System.Web.Script.Serialization
Imports ClosedXML.Excel

Public NotInheritable Class WorkGuideLogExport
    Private Sub New()
    End Sub

    Public Shared Function FilterRows(data As DataTable, selectedIDsJson As String) As DataTable
        Dim ids As Integer()
        Try
            ids = New JavaScriptSerializer().Deserialize (Of Integer())(selectedIDsJson)
            If ids Is Nothing Then Throw New InvalidOperationException("Invalid export selection.")
        Catch ex As ArgumentException
            Throw New InvalidOperationException("Invalid export selection.", ex)
        End Try
        Dim selected As New HashSet(Of Integer)(ids)
        Dim result = data.Clone()
        ' Client IDs only narrow the freshly authorized, filtered query; they never grant access.
        For Each row As DataRow In data.Rows
            If selected.Contains(Convert.ToInt32(row("ID"))) Then result.ImportRow(row)
        Next
        Return result
    End Function

    Public Shared Function CreateWorkbook(data As DataTable) As Byte()
        If data.Rows.Count > 1048575 Then _
            Throw New InvalidOperationException("النتائج تتجاوز سعة ورقة Excel. حدّد فترة زمنية أقصر ثم أعد التصدير.")
        Using workbook As New XLWorkbook()
            Dim sheet = workbook.Worksheets.Add("المشاهدة والتحميل")
            sheet.RightToLeft = True
            Dim headers =
                    {"رقم السجل", "التاريخ والوقت", "رقم المستخدم", "المستخدم", "العلامة التجارية", "التصنيف", "الوثيقة",
                     "النشاط", "التفاصيل", "عنوان IP"}
            For column = 0 To headers.Length - 1
                sheet.Cell(1, column + 1).SetValue (Of String)(headers(column))
            Next
            Dim fields =
                    {"ID", "AddedDate", "User_ID", "User_Name", "Brand_Name", "Category_Name", "Document_Name",
                     "Action_Type", "Action_Details", "IPAddress"}
            For index = 0 To data.Rows.Count - 1
                Dim row = data.Rows(index)
                For column = 0 To fields.Length - 1
                    Dim cell = sheet.Cell(index + 2, column + 1)
                    If row.IsNull(fields(column)) Then Continue For
                    If column = 0 OrElse column = 2 Then
                        cell.SetValue (Of Integer)(Convert.ToInt32(row(fields(column))))
                    ElseIf column = 1 Then
                        cell.SetValue (Of DateTime)(Convert.ToDateTime(row(fields(column))))
                        cell.Style.DateFormat.Format = "dd/mm/yyyy hh:mm:ss"
                    Else
                        Dim value = Convert.ToString(row(fields(column)))
                        If column = 7 Then value = If(value = "1", "مشاهدة وثيقة", "تحميل وثيقة")
                        If value.Length > 32767 Then _
                            Throw _
                                New InvalidOperationException(
                                    "أحد نصوص السجل يتجاوز سعة خلية Excel. حدّد نتائج أخرى للتصدير.")
                        ' Explicit text preserves names/IPs and does not turn leading =,+,-,@ into formulas.
                        cell.SetValue (Of String)(value)
                        cell.DataType = XLCellValues.Text
                    End If
                Next
            Next
            Dim area = sheet.Range(1, 1, data.Rows.Count + 1, headers.Length)
            area.Style.Font.FontName = "Arial"
            area.Style.Font.FontSize = 11
            area.Style.Alignment.Vertical = XLAlignmentVerticalValues.Top
            area.Style.Alignment.WrapText = True
            Dim heading = sheet.Range(1, 1, 1, headers.Length)
            heading.Style.Font.Bold = True
            heading.Style.Font.FontColor = XLColor.White
            heading.Style.Fill.BackgroundColor = XLColor.FromHtml("#245A81")
            sheet.Row(1).Height = 30
            sheet.Columns(1, 10).Width = 25
            sheet.Column(1).Width = 13
            sheet.Column(2).Width = 24
            sheet.Column(3).Width = 14
            sheet.Column(6).Width = 35
            sheet.Column(7).Width = 35
            sheet.Column(9).Width = 60
            sheet.SheetView.FreezeRows(1)
            area.SetAutoFilter()
            Using stream As New MemoryStream()
                workbook.SaveAs(stream)
                Return stream.ToArray()
            End Using
        End Using
    End Function
End Class


