Attribute VB_Name = "PNG"
Option Private Module
Option Explicit

#If VBA7 Then
    Private Declare PtrSafe Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal pDest As LongPtr, ByVal pSrc As LongPtr, ByVal sz As Long)
#Else
    Private Declare Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal pDest As Long, ByVal pSrc As Long, ByVal sz As Long)
#End If

Private Type PngSignature
    psData(7) As Byte
End Type

Private Type PngChunk
    pLength As Long
    pType   As Long
    pData() As Byte
    pCRC    As Long
End Type

Public Enum PngColorType
    pGrayscale = 0
    pTrueColor = 2
    pIndexColor = 3
    pGrayscaleAlpha = 4
    pTrueColorAlpha = 6
End Enum

Private Enum PngCompressionMethod
    Deflate = 0
End Enum

Private Enum PngFilterType
    pNone = 0
    pSub = 1
    pUp = 2
    pAverage = 3
    pPaeth = 4
End Enum

Private Enum PngInterlaceMethod
    pNo = 0
    pAdam7 = 1
End Enum

Public Function GetPNG(ByRef data() As Byte, _
                       ByVal pictWidth As Long, _
                       ByVal pictHeight As Long, _
                       ByVal foreColorRgb As Long, _
                       ByVal backColorRgb As Long, _
                       ByVal tColor As PngColorType) As Byte()
    Dim bitDepth As Long
    Select Case tColor
        Case pTrueColor, pTrueColorAlpha
            bitDepth = 8
        Case pIndexColor
            bitDepth = 1
        Case Else
            Call Err.Raise(5)
    End Select

    Dim psgn As PngSignature
    Call MakePngSignature(psgn)

    Dim ihdr As PngChunk
    Call MakeIHDR( _
        pictWidth, _
        pictHeight, _
        bitDepth, _
        tColor, _
        PngCompressionMethod.Deflate, _
        PngFilterType.pNone, _
        PngInterlaceMethod.pNo, _
        ihdr _
    )

    Dim iplt As PngChunk
    If tColor = PngColorType.pIndexColor Then
        Call MakeIPLT(iplt, foreColorRgb, backColorRgb)
    End If

    Dim idat As PngChunk
    Call MakeIDAT(data, DeflateBType.NoCompression, idat)

    Dim iend As PngChunk
    Call MakeIEND(iend)

    Dim ret() As Byte
    Call ToBytes(psgn, ihdr, iplt, idat, iend, ret)

    GetPNG = ret
End Function

Private Sub MakePngSignature(ByRef psgn As PngSignature)
    With psgn
        .psData(0) = &H89
        .psData(1) = Asc("P")
        .psData(2) = Asc("N")
        .psData(3) = Asc("G")
        .psData(4) = Asc(vbCr)
        .psData(5) = Asc(vbLf)
        .psData(6) = &H1A
        .psData(7) = Asc(vbLf)
    End With
End Sub

Private Sub MakeIHDR(ByVal pictWidth As Long, _
                     ByVal pictHeight As Long, _
                     ByVal bitDepth As Long, _
                     ByVal tColor As PngColorType, _
                     ByVal compressionMethod As Long, _
                     ByVal tFilter As Long, _
                     ByVal interlace As Long, _
                     ByRef ihdr As PngChunk)
    Const STR_IHDR As Long = &H49484452

    Dim bytes() As Byte
    Dim crc As Long

    With ihdr
        .pLength = 13
        .pType = STR_IHDR

        ReDim .pData(.pLength - 1)
        bytes = BitConverter.GetBytes(pictWidth, True)
        Call MoveMemory(VarPtr(.pData(0)), VarPtr(bytes(0)), 4)
        bytes = BitConverter.GetBytes(pictHeight, True)
        Call MoveMemory(VarPtr(.pData(4)), VarPtr(bytes(0)), 4)

        .pData(8) = bitDepth
        .pData(9) = tColor
        .pData(10) = compressionMethod
        .pData(11) = tFilter
        .pData(12) = interlace

        crc = CRC32.Checksum(BitConverter.GetBytes(STR_IHDR, True))
        .pCRC = CRC32.Update(crc, .pData)
    End With
End Sub

Private Sub MakeIPLT(ByRef iplt As PngChunk, ParamArray rgbArray() As Variant)
    Const STR_PLTE As Long = &H504C5445

    Dim idx As Long
    idx = 0

    Dim v   As Variant
    Dim crc As Long

    With iplt
        .pLength = (UBound(rgbArray) + 1) * 3
        .pType = STR_PLTE

        ReDim .pData(.pLength - 1)
        For Each v In rgbArray
            .pData(idx + 0) = CByte(v And &HFF&)
            .pData(idx + 1) = CByte((v And &HFF00&) \ 2 ^ 8)
            .pData(idx + 2) = CByte((v And &HFF0000) \ 2 ^ 16)
            idx = idx + 3
        Next

        crc = CRC32.Checksum(BitConverter.GetBytes(.pType, True))
        .pCRC = CRC32.Update(crc, .pData)
    End With
End Sub

Private Sub MakeIDAT(ByRef data() As Byte, ByVal btype As DeflateBType, ByRef idat As PngChunk)
    Const STR_IDAT As Long = &H49444154

    Dim crc As Long

    With idat
        Call ZLIB.Compress(data, btype, .pData)
        .pLength = UBound(.pData) + 1
        .pType = STR_IDAT
        crc = CRC32.Checksum(BitConverter.GetBytes(STR_IDAT, True))
        .pCRC = CRC32.Update(crc, .pData)
    End With
End Sub

Private Sub MakeIEND(ByRef iend As PngChunk)
    Const STR_IEND As Long = &H49454E44

    With iend
        .pLength = 0
        .pType = STR_IEND
        .pCRC = CRC32.Checksum(BitConverter.GetBytes(STR_IEND, True))
    End With
End Sub

Private Sub ToBytes(ByRef psgn As PngSignature, _
                    ByRef ihdr As PngChunk, _
                    ByRef iplt As PngChunk, _
                    ByRef idat As PngChunk, _
                    ByRef iend As PngChunk, _
                    ByRef buffer() As Byte)
    Dim pfhSize As Long
    pfhSize = 8

    Dim ihdrSize As Long
    ihdrSize = 12 + ihdr.pLength

    Dim ipltSize As Long

    If iplt.pLength > 0 Then
        ipltSize = 12 + iplt.pLength
    Else
        ipltSize = 0
    End If

    Dim idatSize As Long
    idatSize = 12 + idat.pLength

    Dim iendSize As Long
    iendSize = 12 + iend.pLength

    ReDim buffer(pfhSize + ihdrSize + ipltSize + idatSize + iendSize - 1)

    Dim idx As Long
    idx = 0

    With psgn
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(.psData(0)), 8)
        idx = idx + 8
    End With

    Dim bytes() As Byte

    With ihdr
        bytes = BitConverter.GetBytes(.pLength, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
        idx = idx + 4
        bytes = BitConverter.GetBytes(.pType, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
        idx = idx + 4
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(.pData(0)), .pLength)
        idx = idx + .pLength
        bytes = BitConverter.GetBytes(.pCRC, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
        idx = idx + 4
    End With

    If iplt.pLength > 0 Then
        With iplt
            bytes = BitConverter.GetBytes(.pLength, True)
            Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
            idx = idx + 4
            bytes = BitConverter.GetBytes(.pType, True)
            Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
            idx = idx + 4
            Call MoveMemory(VarPtr(buffer(idx)), VarPtr(.pData(0)), .pLength)
            idx = idx + .pLength
            bytes = BitConverter.GetBytes(.pCRC, True)
            Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
            idx = idx + 4
        End With
    End If

    With idat
        bytes = BitConverter.GetBytes(.pLength, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
        idx = idx + 4
        bytes = BitConverter.GetBytes(.pType, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
        idx = idx + 4
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(.pData(0)), .pLength)
        idx = idx + .pLength
        bytes = BitConverter.GetBytes(.pCRC, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
        idx = idx + 4
    End With

    With iend
        bytes = BitConverter.GetBytes(.pLength, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
        idx = idx + 4
        bytes = BitConverter.GetBytes(.pType, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
        idx = idx + 4
        bytes = BitConverter.GetBytes(.pCRC, True)
        Call MoveMemory(VarPtr(buffer(idx)), VarPtr(bytes(0)), 4)
    End With
End Sub
