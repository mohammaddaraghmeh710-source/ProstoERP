Imports Prosto_ERP_ClassLibrary

Public Class EditShift
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            SystemAdministrationUI.Redirect(Me, "/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            SystemAdministrationUI.Redirect(Me, "/Default.aspx")
        End If
        If Not Page.IsPostBack Then
            fillData()
        End If
    End Sub

    Protected Sub fillData()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim ID = CInt(Request.QueryString("ID"))
            For Each item In db.Select_Shift_ByID(ID)
                txtFullNameAr.Text = item.Title_Ar
                txtFullNameEn.Text = item.Title_En

                ' أوقات العمل
                If item.Start_Time IsNot Nothing Then
                    Dim ts = CType(item.Start_Time, TimeSpan)
                    txtStartTime.Text = ts.ToString("hh\:mm")
                End If

                If item.End_Time IsNot Nothing Then
                    Dim ts = CType(item.End_Time, TimeSpan)
                    txtEndTime.Text = ts.ToString("hh\:mm")
                End If

                If item.Start_Time_Ramadan IsNot Nothing Then
                    Dim ts = CType(item.Start_Time_Ramadan, TimeSpan)
                    txtStartTimeRamadan.Text = ts.ToString("hh\:mm")
                End If

                If item.End_Time_Ramadan IsNot Nothing Then
                    Dim ts = CType(item.End_Time_Ramadan, TimeSpan)
                    txtEndTimeRamadan.Text = ts.ToString("hh\:mm")
                End If

                cbIsApproved.Checked = If(item.IsActive.HasValue, item.IsActive.Value, False)
            Next
        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)

        Dim ID = CInt(Request.QueryString("ID"))
        Dim NameAr As String = txtFullNameAr.Text
        Dim NameEn As String = txtFullNameEn.Text
        Dim ChActive As Boolean = cbIsApproved.Checked

        ' --- قراءة الأوقات كـ TimeSpan? ---
        Dim startTime As Nullable(Of TimeSpan) = Nothing
        Dim endTime As Nullable(Of TimeSpan) = Nothing
        Dim startRamadan As Nullable(Of TimeSpan) = Nothing
        Dim endRamadan As Nullable(Of TimeSpan) = Nothing

        Dim ts As TimeSpan

        If Not String.IsNullOrWhiteSpace(txtStartTime.Text) AndAlso TimeSpan.TryParse(txtStartTime.Text, ts) Then
            startTime = ts
        End If

        If Not String.IsNullOrWhiteSpace(txtEndTime.Text) AndAlso TimeSpan.TryParse(txtEndTime.Text, ts) Then
            endTime = ts
        End If

        If _
            Not String.IsNullOrWhiteSpace(txtStartTimeRamadan.Text) AndAlso
            TimeSpan.TryParse(txtStartTimeRamadan.Text, ts) Then
            startRamadan = ts
        End If

        If Not String.IsNullOrWhiteSpace(txtEndTimeRamadan.Text) AndAlso TimeSpan.TryParse(txtEndTimeRamadan.Text, ts) _
            Then
            endRamadan = ts
        End If

        Using db As New Prosto_ERP_DataClassesDataContext
            ' نفترض أن Update_Shift_ByID في الـ DBML أصبح:
            ' Update_Shift_ByID(ID, Title_Ar, Title_En, Start_Time, End_Time, Start_Time_Ramadan, End_Time_Ramadan, ModifyUser, IsActive)
            db.Update_Shift_ByID(
                iD := ID,
                title_Ar := NameAr,
                title_En := NameEn,
                start_Time := startTime,
                end_Time := endTime,
                start_Time_Ramadan := startRamadan,
                end_Time_Ramadan := endRamadan,
                modifyUser := SessionManager.GetInstance.Users.UserID
                )
        End Using

        If Not SystemAdministrationUI.Complete(Me) Then LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Shift/ManageShift.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Shift/ManageShift.aspx", True)
    End Sub
End Class


