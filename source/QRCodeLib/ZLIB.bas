Attribute VB_Name = "Zlib"
Option Private Module
Option Explicit

#If VBA7 Then
    Private Declare PtrSafe Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal pDest As LongPtr, ByVal pSrc As LongPtr, ByVal sz As Long)
#Else
    Private Declare Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal pDest As Long, ByVal pSrc As Long, ByVal sz As Long)
#End If

Private Enum CompressionLevel
    Fastest = 0
    Fast = 1
    Default = 2
    Slowest = 3
End Enum

Public Sub Compress(ByRef data() As Byte, ByVal btype As DeflateBType, ByRef buffer() As Byte)
    Dim cmf As Byte
    cmf = &H78

    Dim fdict As Byte
    fdict = &H0

    Dim flevel As Byte
    flevel = CompressionLevel.Default * 2 ^ 6

    Dim flg As Byte
    flg = flevel + fdict

    Dim fcheck As Byte
    fcheck = 31 - ((cmf * 2 ^ 8 + flg) Mod 31)

    flg = flg + fcheck

    Dim bytes() As Byte
    Call Deflate.Compress(data, btype, bytes)

    Dim adler As Long
    adler = ADLER32.Checksum(data)

    Dim sz As Long
    sz = UBound(bytes) + 1

    ReDim buffer(1 + 1 + sz + 4 - 1)

    Dim idx As Long
    idx = 0

    Dim lbe As Long

    Call MoveMemory(VarPtr(buffer(idx)), VarPtr(cmf), 1)
    idx = idx + 1
    Call MoveMemory(VarPtr(buffer(idx)), VarPtr(flg), 1)
    idx = idx + 1
    Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), sz)
    idx = idx + sz
    lbe = BitConverter.ToBigEndian(adler)
    Call MoveMemory(VarPtr(buffer(idx)), VarPtr(lbe), 4)
End Sub
