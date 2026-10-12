Imports System.Security.Cryptography
Imports System.IO

Public NotInheritable Class EncryptDecrypt
    Private Sub New()
    End Sub
    Private Const SEncryptionKey As String = "Echo1234"

    Private Shared _key As Byte() = {}
    Private Shared ReadOnly Iv As Byte() = {&H12, &H34, &H56, &H78, &H90, &HAB, _
        &HCD, &HEF}
    Public Shared Function Decrypt(stringToDecrypt As String) As String

        stringToDecrypt = stringToDecrypt.Replace(" ", "+")
        Dim inputByteArray As Byte() = New Byte(stringToDecrypt.Length) {}
        Try
            _key = Encoding.UTF8.GetBytes(SEncryptionKey)
            Dim des As New DESCryptoServiceProvider()
            inputByteArray = Convert.FromBase64String(stringToDecrypt)

            Using ms As New MemoryStream()
                Using cs As New CryptoStream(ms, des.CreateDecryptor(_key, Iv), CryptoStreamMode.Write)
                    cs.Write(inputByteArray, 0, inputByteArray.Length)
                    cs.FlushFinalBlock()
                End Using
                Dim encoding__1 As Encoding = Encoding.UTF8
                Return encoding__1.GetString(ms.ToArray())
            End Using
        Catch
            Return String.Empty
        End Try
    End Function

    Public Shared Function Encrypt(stringToEncrypt As String) As String
        Try
            _key = Encoding.UTF8.GetBytes(SEncryptionKey)
            Dim des As New DESCryptoServiceProvider()
            Dim inputByteArray As Byte() = Encoding.UTF8.GetBytes(stringToEncrypt)

            Using ms As New MemoryStream()
                Using cs As New CryptoStream(ms, des.CreateEncryptor(_key, Iv), CryptoStreamMode.Write)
                    cs.Write(inputByteArray, 0, inputByteArray.Length)
                    cs.FlushFinalBlock()
                End Using

                Return Convert.ToBase64String(ms.ToArray())
            End Using
        Catch e As Exception
            Return e.Message
        End Try
    End Function
End Class