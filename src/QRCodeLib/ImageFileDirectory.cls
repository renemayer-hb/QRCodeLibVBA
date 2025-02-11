VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ImageFileDirectory"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private m_entries As Collection
Private m_nextIFDOffset As Long

Private Sub Class_Initialize()
    Set m_entries = New Collection
    m_nextIFDOffset = 0
End Sub

Public Property Get NextIFDOffset() As Long
    NextIFDOffset = m_nextIFDOffset
End Property
Public Property Let NextIFDOffset(ByVal Value As Long)
    m_nextIFDOffset = Value
End Property

Public Property Get Length() As Long
    Length = 2 + 4 + (12 * m_entries.Count)
End Property

Public Function GetEntries() As IFDEntry()
    Dim ret() As IFDEntry
    ReDim ret(m_entries.Count - 1)

    Dim entry As IFDEntry
    Dim idx As Long
    idx = 0
    For Each entry In m_entries
        Set ret(idx) = entry
        idx = idx + 1
    Next

    GetEntries = ret
End Function

Public Function GetBytes() As Byte()
    Dim buf As New Collection
    Dim i As Long
    Dim temp() As Byte

    temp = BitConverter.GetBytes(CInt(m_entries.Count))
    For i = 0 To UBound(temp)
        Call buf.Add(temp(i))
    Next

    Dim entry As IFDEntry
    For Each entry In m_entries
        temp = entry.GetBytes()
        For i = 0 To UBound(temp)
            Call buf.Add(temp(i))
        Next
    Next

    temp = BitConverter.GetBytes(m_nextIFDOffset)
    For i = 0 To UBound(temp)
        Call buf.Add(temp(i))
    Next

    Dim ret() As Byte
    ReDim ret(buf.Count - 1)

    Dim v As Variant
    Dim idx
    idx = 0
    For Each v In buf
        ret(idx) = CByte(v)
        idx = idx + 1
    Next

    GetBytes = ret
End Function

Public Function Add(ByVal tag As TagID, ByVal v As Long) As IFDEntry
    Dim ret As New IFDEntry
    Call m_entries.Add(ret)

    ret.TagID = tag
    ret.Value = v
    ret.Count = 1

    Select Case tag
        Case TagID.ImageWidth
            ret.FieldType = TiffFieldType.Long
        Case TagID.ImageLength
            ret.FieldType = TiffFieldType.Long
        Case TagID.BitsPerSample
            ret.FieldType = TiffFieldType.Short
        Case TagID.Compression
            ret.FieldType = TiffFieldType.Short
        Case TagID.PhotometricInterpretation
            ret.FieldType = TiffFieldType.Short
        Case TagID.StripOffsets
            ret.FieldType = TiffFieldType.Long
        Case TagID.SamplesPerPixel
            ret.FieldType = TiffFieldType.Short
        Case TagID.RowsPerStrip
            ret.FieldType = TiffFieldType.Long
        Case TagID.StripByteCounts
            ret.FieldType = TiffFieldType.Long
        Case TagID.XResolution
            ret.FieldType = TiffFieldType.Rational
        Case TagID.YResolution
            ret.FieldType = TiffFieldType.Rational
        Case TagID.ColorMap
            ret.FieldType = TiffFieldType.Short
        Case Else
            Call Err.Raise(5)
    End Select

    Set Add = ret
End Function
