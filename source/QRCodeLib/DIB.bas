Attribute VB_Name = "DIB"
Option Private Module
Option Explicit

#If VBA7 Then
    Private Declare PtrSafe Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal pDest As LongPtr, ByVal pSrc As LongPtr, ByVal sz As Long)
#Else
    Private Declare Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal pDest As Long, ByVal pSrc As Long, ByVal sz As Long)
#End If

Private Type BitmapFileHeader
    bfType      As Integer
    bfSize      As Long
    bfReserved1 As Integer
    bfReserved2 As Integer
    bfOffBits   As Long
End Type

Private Type BitmapInfoHeader
    biSize          As Long
    biWidth         As Long
    biHeight        As Long
    biPlanes        As Integer
    biBitCount      As Integer
    biCompression   As Long
    biSizeImage     As Long
    biXPelsPerMeter As Long
    biYPelsPerMeter As Long
    biClrUsed       As Long
    biClrImportant  As Long
End Type

Private Type RgbQuad
    rgbBlue     As Byte
    rgbGreen    As Byte
    rgbRed      As Byte
    rgbReserved As Byte
End Type

Public Function BuildMonochromeBin(ByRef bitmapData() As Byte, _
                                   ByVal pictWidth As Long, _
                                   ByVal pictHeight As Long, _
                                   ByVal foreColorRGB As Long, _
                                   ByVal backColorRGB As Long) As Byte()
    Dim bfh As BitmapFileHeader
    With bfh
        .bfType = &H4D42
        .bfSize = 62 + (UBound(bitmapData) + 1)
        .bfReserved1 = 0
        .bfReserved2 = 0
        .bfOffBits = 62
    End With

    Dim bih As BitmapInfoHeader
    With bih
        .biSize = 40
        .biWidth = pictWidth
        .biHeight = pictHeight
        .biPlanes = 1
        .biBitCount = 1
        .biCompression = 0
        .biSizeImage = 0
        .biXPelsPerMeter = 0
        .biYPelsPerMeter = 0
        .biClrUsed = 0
        .biClrImportant = 0
    End With

    Dim palette(1) As RgbQuad

    With palette(0)
        .rgbBlue = CByte((foreColorRGB And &HFF0000) \ 2 ^ 16)
        .rgbGreen = CByte((foreColorRGB And &HFF00&) \ 2 ^ 8)
        .rgbRed = CByte(foreColorRGB And &HFF&)
        .rgbReserved = 0
    End With

    With palette(1)
        .rgbBlue = CByte((backColorRGB And &HFF0000) \ 2 ^ 16)
        .rgbGreen = CByte((backColorRGB And &HFF00&) \ 2 ^ 8)
        .rgbRed = CByte(backColorRGB And &HFF&)
        .rgbReserved = 0
    End With

    Dim ret() As Byte
    ReDim ret(62 + UBound(bitmapData))

    With bfh
        Call MoveMemory(VarPtr(ret(0)), VarPtr(.bfType), 2)
        Call MoveMemory(VarPtr(ret(2)), VarPtr(.bfSize), 4)
        Call MoveMemory(VarPtr(ret(6)), VarPtr(.bfReserved1), 2)
        Call MoveMemory(VarPtr(ret(8)), VarPtr(.bfReserved2), 2)
        Call MoveMemory(VarPtr(ret(10)), VarPtr(.bfOffBits), 4)
    End With

    With bih
        Call MoveMemory(VarPtr(ret(14)), VarPtr(.biSize), 4)
        Call MoveMemory(VarPtr(ret(18)), VarPtr(.biWidth), 4)
        Call MoveMemory(VarPtr(ret(22)), VarPtr(.biHeight), 4)
        Call MoveMemory(VarPtr(ret(26)), VarPtr(.biPlanes), 2)
        Call MoveMemory(VarPtr(ret(28)), VarPtr(.biBitCount), 2)
        Call MoveMemory(VarPtr(ret(30)), VarPtr(.biCompression), 4)
        Call MoveMemory(VarPtr(ret(34)), VarPtr(.biSizeImage), 4)
        Call MoveMemory(VarPtr(ret(38)), VarPtr(.biXPelsPerMeter), 4)
        Call MoveMemory(VarPtr(ret(42)), VarPtr(.biYPelsPerMeter), 4)
        Call MoveMemory(VarPtr(ret(46)), VarPtr(.biClrUsed), 4)
        Call MoveMemory(VarPtr(ret(50)), VarPtr(.biClrImportant), 4)
    End With

    Call MoveMemory(VarPtr(ret(54)), VarPtr(palette(0)), 8)
    Call MoveMemory(VarPtr(ret(62)), VarPtr(bitmapData(0)), UBound(bitmapData) + 1)

    BuildMonochromeBin = ret
End Function

Public Function BuildTrueColorBin(ByRef bitmapData() As Byte, _
                                  ByVal pictWidth As Long, _
                                  ByVal pictHeight As Long) As Byte()
    Dim bfh As BitmapFileHeader
    With bfh
        .bfType = &H4D42
        .bfSize = 54 + (UBound(bitmapData) + 1)
        .bfReserved1 = 0
        .bfReserved2 = 0
        .bfOffBits = 54
    End With

    Dim bih As BitmapInfoHeader
    With bih
        .biSize = 40
        .biWidth = pictWidth
        .biHeight = pictHeight
        .biPlanes = 1
        .biBitCount = 24
        .biCompression = 0
        .biSizeImage = 0
        .biXPelsPerMeter = 0
        .biYPelsPerMeter = 0
        .biClrUsed = 0
        .biClrImportant = 0
    End With

    Dim ret() As Byte
    ReDim ret(54 + UBound(bitmapData))

    With bfh
        Call MoveMemory(VarPtr(ret(0)), VarPtr(.bfType), 2)
        Call MoveMemory(VarPtr(ret(2)), VarPtr(.bfSize), 4)
        Call MoveMemory(VarPtr(ret(6)), VarPtr(.bfReserved1), 2)
        Call MoveMemory(VarPtr(ret(8)), VarPtr(.bfReserved2), 2)
        Call MoveMemory(VarPtr(ret(10)), VarPtr(.bfOffBits), 4)
    End With

    With bih
        Call MoveMemory(VarPtr(ret(14)), VarPtr(.biSize), 4)
        Call MoveMemory(VarPtr(ret(18)), VarPtr(.biWidth), 4)
        Call MoveMemory(VarPtr(ret(22)), VarPtr(.biHeight), 4)
        Call MoveMemory(VarPtr(ret(26)), VarPtr(.biPlanes), 2)
        Call MoveMemory(VarPtr(ret(28)), VarPtr(.biBitCount), 2)
        Call MoveMemory(VarPtr(ret(30)), VarPtr(.biCompression), 4)
        Call MoveMemory(VarPtr(ret(34)), VarPtr(.biSizeImage), 4)
        Call MoveMemory(VarPtr(ret(38)), VarPtr(.biXPelsPerMeter), 4)
        Call MoveMemory(VarPtr(ret(42)), VarPtr(.biYPelsPerMeter), 4)
        Call MoveMemory(VarPtr(ret(46)), VarPtr(.biClrUsed), 4)
        Call MoveMemory(VarPtr(ret(50)), VarPtr(.biClrImportant), 4)
    End With

    Call MoveMemory(VarPtr(ret(54)), VarPtr(bitmapData(0)), UBound(bitmapData) + 1)

    BuildTrueColorBin = ret
End Function
