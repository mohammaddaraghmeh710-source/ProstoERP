
Imports System.DirectoryServices

Public Class ActiveDirectoryChecker
    Public Shared Function CheckDomainUser(username As String, password As String) As Boolean
        Dim isValid = False

        Dim ADPath As String = ConfigurationManager.ConnectionStrings("ADconnectionString").ConnectionString
        Dim entry = New DirectoryEntry(ADPath, username, password)

        Try
            Dim obj As Object = entry.NativeObject
            Dim search = New DirectorySearcher(entry)

            search.Filter = "(&(objectClass=user)(SAMAccountName=" & username & "))"

            Dim result As SearchResult = search.FindOne()
            If (result Is Nothing) Then
                Return False
            Else
                Return True
            End If
        Catch
            Return False
        End Try

        Return isValid
    End Function
End Class


