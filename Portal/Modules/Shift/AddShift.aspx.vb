Imports System

Partial Public Class AddShift
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            SystemAdministrationUI.Redirect(Me, "/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            SystemAdministrationUI.Redirect(Me, "/Default.aspx")
        End If

    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)

        Dim NameAr As String = txtFullNameAr.Text
        Dim NameEn As String = txtFullNameEn.Text
        'Dim isActive As Boolean = cbIsApproved.Checked

        ' --- قراءة الأوقات كـ TimeSpan? ---
        Dim startTime As System.Nullable(Of TimeSpan) = Nothing
        Dim endTime As System.Nullable(Of TimeSpan) = Nothing
        Dim startRamadan As System.Nullable(Of TimeSpan) = Nothing
        Dim endRamadan As System.Nullable(Of TimeSpan) = Nothing

        Dim ts As TimeSpan

        If Not String.IsNullOrWhiteSpace(txtStartTime.Text) AndAlso TimeSpan.TryParse(txtStartTime.Text, ts) Then
            startTime = ts
        End If

        If Not String.IsNullOrWhiteSpace(txtEndTime.Text) AndAlso TimeSpan.TryParse(txtEndTime.Text, ts) Then
            endTime = ts
        End If

        If Not String.IsNullOrWhiteSpace(txtStartTimeRamadan.Text) AndAlso TimeSpan.TryParse(txtStartTimeRamadan.Text, ts) Then
            startRamadan = ts
        End If

        If Not String.IsNullOrWhiteSpace(txtEndTimeRamadan.Text) AndAlso TimeSpan.TryParse(txtEndTimeRamadan.Text, ts) Then
            endRamadan = ts
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            ' تأكد أن توقيع الإجراء في الـ DBML يطابق البراميتر التالية:
            ' Insert_Shift(Title_Ar, Title_En, Start_Time, End_Time,
            '              Start_Time_Ramadan, End_Time_Ramadan,
            '              AddedUser, IsActive, NewID)

            Dim newId As Integer = 0

            db.Insert_Shift(
                title_Ar:=NameAr,
                title_En:=NameEn,
                start_Time:=startTime,
                end_Time:=endTime,
                start_Time_Ramadan:=startRamadan,
                end_Time_Ramadan:=endRamadan,
                addedUser:=SessionManager.GetInstance.Users.UserID,
                newID:=newId
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
