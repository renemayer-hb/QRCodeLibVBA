Attribute VB_Name = "BitConverter"
Option Private Module
Option Explicit

Public Function GetBytes(ByVal arg As Variant, Optional ByVal reverse As Boolean = False) As Byte()
    Dim ret() As Byte
    Dim temp As Byte

    Select Case VarType(arg)
        Case VbVarType.vbByte
            ReDim ret(0)
            ret(0) = arg
        Case VbVarType.vbInteger
            ReDim ret(1)
            ret(0) = arg And &HFF&
            ret(1) = (arg And &HFF00&) \ 2 ^ 8

            If reverse Then
                temp = ret(0)
                ret(0) = ret(1)
                ret(1) = temp
            End If
        Case VbVarType.vbLong
            ReDim ret(3)
            ret(0) = arg And &HFF&
            ret(1) = (arg And &HFF00&) \ 2 ^ 8
            ret(2) = (arg And &HFF0000) \ 2 ^ 16
            ret(3) = (arg And &HFF000000) \ 2 ^ 24 And &HFF&

            If reverse Then
                temp = ret(0)
                ret(0) = ret(3)
                ret(3) = temp

                temp = ret(1)
                ret(1) = ret(2)
                ret(2) = temp
            End If
        Case Else
            Call Err.Raise(5)
    End Select

    GetBytes = ret
End Function

Public Function ToBigEndian(ByVal arg As Variant) As Variant
    Dim ret As Variant

    Dim temp() As Byte
    temp = GetBytes(arg)

    Select Case VarType(arg)
        Case VbVarType.vbByte
            ret = temp(0)
        Case VbVarType.vbInteger
            If (temp(0) And &H80) > 0 Then
                ret = (temp(0) And &H7F) * 2 ^ 8
                ret = ret Or &H8000
            Else
                ret = temp(0) * 2 ^ 8
            End If

            ret = CInt(ret Or temp(1))

        Case VbVarType.vbLong
            If (temp(0) And &H80) > 0 Then
                ret = CLng((temp(0) And &H7F) * 2 ^ 24)
                ret = ret Or &H80000000
            Else
                ret = CLng((temp(0)) * 2 ^ 24)
            End If

            ret = ret Or ((temp(1)) * 2 ^ 16)
            ret = ret Or ((temp(2)) * 2 ^ 8)
            ret = ret Or (temp(3))
        Case Else
            Call Err.Raise(5)
    End Select

    ToBigEndian = ret
End Function
