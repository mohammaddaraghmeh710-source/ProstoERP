Imports System.Linq

Public Class ManageWorkGuide_Documents
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBrands()
            FillCategories()
            FillData()
        End If

    End Sub

    Private Sub FillBrands()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim brands = db.Select_Brands_All().ToList()

            ddlBrand.DataSource = brands
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()

            ddlBrand.Items.Insert(0, New ListItem("جميع العلامات التجارية", "0"))

        End Using
    End Sub

    Private Sub FillCategories()

        ddlCategory.Items.Clear()
        ddlCategory.Items.Insert(0, New ListItem("جميع التصنيفات", "0"))

        If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
            Return
        End If

        Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim categories = db.Select_Work_Guide_Categories_Tree_ByBrand(BrandID, Nothing).ToList()

            For Each item In categories
                ddlCategory.Items.Add(New ListItem(item.Tree_Title_Ar, item.ID.ToString()))
            Next

        End Using

    End Sub

    Private Sub FillData()

        lblError.Visible = False
        lblError.Text = ""

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim BrandID As Integer? = Nothing
            Dim CategoryID As Integer? = Nothing

            If ddlBrand.SelectedValue IsNot Nothing AndAlso ddlBrand.SelectedValue <> "0" Then
                BrandID = CInt(ddlBrand.SelectedValue)
            End If

            If ddlCategory.SelectedValue IsNot Nothing AndAlso ddlCategory.SelectedValue <> "0" Then
                CategoryID = CInt(ddlCategory.SelectedValue)
            End If

            Dim Data = db.Select_Work_Guide_Documents_All(BrandID, CategoryID).AsQueryable()
            Data = Data.OrderByDescending(Function(x) x.ID)

            lstData.DataSource = Data.ToList()
            lstData.DataBind()

        End Using

    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillCategories()
        FillData()
    End Sub

    Protected Sub ddlCategory_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillData()
    End Sub

    Private Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstData.ItemCommand

        Try

            Select Case e.CommandName

                Case "Edit"

                    Dim ID As Integer = CType(e.CommandArgument, Integer)
                    Response.Redirect("/Modules/WorkGuide_Documents/EditWorkGuide_Documents.aspx?ID=" & ID.ToString())

                Case "DeleteItem"

                    Dim ID As Integer = CType(e.CommandArgument, Integer)

                    Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
                        db.Update_Work_Guide_Document_IsDelete_ByID(ID, True, SessionManager.GetInstance.Users.UserID)
                    End Using

                    FillData()

                Case "Versions"

                    Dim DocumentID As Integer = CType(e.CommandArgument, Integer)

                    hfSelectedDocumentID.Value = DocumentID.ToString()

                    FillVersions(DocumentID)

                    ShowVersionsModal()

            End Select

        Catch ex As Exception

            ShowError("حدث خطأ أثناء تنفيذ العملية: " & ex.Message)

        End Try

    End Sub

    Private Sub FillVersions(DocumentID As Integer)

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim versions = db.Select_Work_Guide_Document_Versions_ByDocumentID(DocumentID).ToList()

            lstVersions.DataSource = versions
            lstVersions.DataBind()

        End Using

    End Sub

    Private Sub lstVersions_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstVersions.ItemCommand

        Try

            Select Case e.CommandName

                Case "RestoreVersion"

                    Dim VersionID As Integer = CType(e.CommandArgument, Integer)
                    Dim DocumentID As Integer = CInt(hfSelectedDocumentID.Value)

                    Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                        db.Restore_Work_Guide_Document_Version(
                            DocumentID,
                            VersionID,
                            SessionManager.GetInstance.Users.UserID
                        )

                    End Using

                    FillVersions(DocumentID)
                    FillData()

                    ShowVersionsModal()

            End Select

        Catch ex As Exception

            ShowError("حدث خطأ أثناء استرجاع النسخة: " & ex.Message)

        End Try

    End Sub

    Private Sub ShowVersionsModal()

        Dim script As String = "
            setTimeout(function () {
                var modalElement = document.getElementById('versionsModal');
                if (modalElement) {
                    var modal = new bootstrap.Modal(modalElement);
                    modal.show();
                }
            }, 300);
        "

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "ShowVersionsModal", script, True)

    End Sub

    Private Sub ShowError(message As String)

        lblError.Text = message
        lblError.Visible = True

    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)

        Response.Redirect("/Modules/WorkGuide_Documents/AddWorkGuide_Documents.aspx")

    End Sub

    Public Function FormatFileSize(value As Object) As String

        If value Is Nothing OrElse IsDBNull(value) Then
            Return "-"
        End If

        Dim size As Decimal = Convert.ToDecimal(value)

        If size < 1024 Then
            Return size.ToString("N0") & " B"
        ElseIf size < 1024 * 1024 Then
            Return (size / 1024).ToString("N2") & " KB"
        Else
            Return (size / 1024 / 1024).ToString("N2") & " MB"
        End If

    End Function

End Class