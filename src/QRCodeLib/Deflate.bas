Attribute VB_Name = "Deflate"
Option Private Module
Option Explicit

#If VBA7 Then
    Private Declare PtrSafe Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal pDest As LongPtr, ByVal pSrc As LongPtr, ByVal sz As Long)
#Else
    Private Declare Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal pDest As Long, ByVal pSrc As Long, ByVal sz As Long)
#End If

Public Enum DeflateBType
    NoCompression = 0
    CompressedWithFixedHuffmanCodes = 1
    CompressedWithDynamicHuffmanCodes = 2
    Reserved = 3
End Enum

Public Sub Compress(ByRef data() As Byte, ByVal btype As DeflateBType, ByRef buffer() As Byte)
    If btype <> DeflateBType.NoCompression Then Call Err.Raise(5)

    Dim bytesLen As Long
    bytesLen = UBound(data) + 1

    Dim quotient As Long
    quotient = bytesLen \ &HFFFF&

    Dim remainder As Long
    remainder = bytesLen Mod &HFFFF&

    Dim bufferSize As Long
    bufferSize = quotient * (1 + 4 + &HFFFF&)

    If remainder > 0 Then
        bufferSize = bufferSize + (1 + 4 + remainder)
    End If

    ReDim buffer(bufferSize - 1)

#If VBA7 Then
    Dim srcPtr As LongPtr
    Dim dstPtr As LongPtr
#Else
    Dim srcPtr As Long
    Dim dstPtr As Long
#End If

    Dim bfinal As Long
    Dim dLen   As Long
    Dim dNLen  As Long

    Dim idx As Long
    idx = 0

    Dim temp() As Byte

    Dim i As Long
    For i = 0 To quotient - 1
        bfinal = 0
        buffer(idx) = bfinal Or (btype * 2 ^ 1)
        idx = idx + 1

        dLen = &HFFFF&
        temp = BitConverter.GetBytes(dLen)
        buffer(idx) = temp(0)
        buffer(idx + 1) = temp(1)
        idx = idx + 2

        dNLen = dLen Xor &HFFFF&
        temp = BitConverter.GetBytes(dNLen)
        buffer(idx) = temp(0)
        buffer(idx + 1) = temp(1)
        idx = idx + 2

        srcPtr = VarPtr(data(&HFFFF& * i))
        dstPtr = VarPtr(buffer(idx))
        Call MoveMemory(dstPtr, srcPtr, &HFFFF&)
        idx = idx + &HFFFF&
    Next

    If remainder > 0 Then
        bfinal = 1
        buffer(idx) = bfinal Or (btype * 2 ^ 1)
        idx = idx + 1

        dLen = remainder
        temp = BitConverter.GetBytes(dLen)
        buffer(idx) = temp(0)
        buffer(idx + 1) = temp(1)
        idx = idx + 2

        dNLen = dLen Xor &HFFFF&
        temp = BitConverter.GetBytes(dNLen)
        buffer(idx) = temp(0)
        buffer(idx + 1) = temp(1)
        idx = idx + 2

        srcPtr = VarPtr(data(&HFFFF& * quotient))
        dstPtr = VarPtr(buffer(idx))
        Call MoveMemory(dstPtr, srcPtr, remainder)
        idx = idx + remainder
    End If
End Sub
