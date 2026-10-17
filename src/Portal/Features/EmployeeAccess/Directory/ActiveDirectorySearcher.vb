
Imports System.DirectoryServices

Public Class ActiveDirectorySearcher
    Public Shared Function GetSearchedUsers(ADUser As String) As List(Of ADuserData)
        Dim ADUsers As New List(Of ADuserData)
        Try
            Dim ADPath As String = ConfigurationManager.ConnectionStrings("ADconnectionString").ConnectionString
            Dim entry = New DirectoryEntry(ADPath, "alaa.a", "ala'a5646596666")
            'Dim entry As DirectoryEntry = New DirectoryEntry(ADPath)
            Dim search = New DirectorySearcher(entry)
            search.Filter = "(&(objectClass=user))"
            Dim results As SearchResultCollection = search.FindAll()

            For Each searchResult As SearchResult In results
                If searchResult.Properties("sAMAccountName")(0).ToString.ToLower().Contains(ADUser.ToLower()) Then
                    Dim ADUserObj As New ADuserData()
                    Dim firstName As String = String.Empty
                    Dim lastName As String = String.Empty
                    If Not searchResult.Properties("givenName").Count <= 0 Then
                        firstName = searchResult.Properties("givenName")(0)
                    End If
                    If searchResult.Properties("sn").Count > 0 Then
                        lastName = searchResult.Properties("sn")(0)
                    End If

                    ADUserObj.EmployeeName = firstName + lastName
                    ADUserObj.Username = searchResult.Properties("sAMAccountName")(0)

                    ADUsers.Add(ADUserObj)
                End If
            Next
            Return ADUsers
        Catch ex As Exception
            Return ADUsers
        End Try
    End Function

    Public Shared Function GetSingleUsers(ADUser As String) As ADuserData
        Dim ADUsers As ADuserData
        Try
            Dim ADPath As String = ConfigurationManager.ConnectionStrings("ADconnectionString").ConnectionString
            Dim entry = New DirectoryEntry(ADPath, "alaa.a", "ala'a5646596666")
            'Dim entry As DirectoryEntry = New DirectoryEntry(ADPath)
            Dim search = New DirectorySearcher(entry)
            search.Filter = "(&(objectClass=user))"
            Dim results As SearchResultCollection = search.FindAll()

            For Each searchResult As SearchResult In results
                If searchResult.Properties("sAMAccountName")(0).ToString.ToLower() = ADUser.ToLower() Then
                    ADUsers = New ADuserData()
                    Dim firstName As String = String.Empty
                    Dim lastName As String = String.Empty
                    If Not searchResult.Properties("givenName").Count <= 0 Then
                        firstName = searchResult.Properties("givenName")(0)
                    End If
                    If searchResult.Properties("sn").Count > 0 Then
                        lastName = searchResult.Properties("sn")(0)
                    End If

                    ADUsers.EmployeeName = firstName + lastName
                    ADUsers.Username = searchResult.Properties("sAMAccountName")(0)

                End If
            Next
            Return ADUsers
        Catch ex As Exception
            Return ADUsers
        End Try
    End Function
End Class


