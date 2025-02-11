VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Symbols"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Private m_items  As Collection

Private m_minVersion            As Long
Private m_maxVersion            As Long
Private m_errorCorrectionLevel  As ErrorCorrectionLevel
Private m_structuredAppend      As Boolean
Private m_encoding              As Encoding

Private m_parity As Long

Private m_currSymbol As Symbol

Private m_encNum    As IQRCodeEncoder
Private m_encAlpha  As IQRCodeEncoder
Private m_encByte   As IQRCodeEncoder
Private m_encKanji  As IQRCodeEncoder

Private Sub Class_Initialize()
    Set m_encNum = New NumericEncoder
    Set m_encAlpha = New AlphanumericEncoder
End Sub

Friend Sub Init(ByVal ecLevel As ErrorCorrectionLevel, _
                ByVal maxVer As Long, _
                ByVal allowStructuredAppend As Boolean, _
                ByVal charEncoding As Encoding)
    If Not (Constants.MIN_VERSION <= maxVer And maxVer <= Constants.MAX_VERSION) Then
        Call Err.Raise(5)
    End If

    Set m_items = New Collection

    m_minVersion = Constants.MIN_VERSION
    m_maxVersion = maxVer
    m_errorCorrectionLevel = ecLevel
    m_structuredAppend = allowStructuredAppend
    Set m_encoding = charEncoding

    m_parity = 0

    If Charset.IsJP(charEncoding.Charset) Then
        Set m_encKanji = New KanjiEncoder
        Call m_encKanji.Init(charEncoding)
    End If

    Set m_encByte = New ByteEncoder
    Call m_encByte.Init(charEncoding)

    Set m_currSymbol = New Symbol
    Call m_currSymbol.Init(Me)
    Call m_items.Add(m_currSymbol)
End Sub

Public Property Get Item(ByVal idx As Long) As Symbol
Attribute Item.VB_UserMemId = 0
' Default Member [Attribute Item.VB_UserMemId = 0]
    Set Item = m_items(idx + 1)
End Property

Public Property Get Count() As Long
    Count = m_items.Count
End Property

Friend Property Get StructuredAppend() As Boolean
    StructuredAppend = m_structuredAppend
End Property

Friend Property Get Parity() As Long
    Parity = m_parity
End Property

Friend Property Get MinVersion() As Long
    MinVersion = m_minVersion
End Property
Friend Property Let MinVersion(ByVal Value As Long)
    m_minVersion = Value
End Property

Friend Property Get MaxVersion() As Long
    MaxVersion = m_maxVersion
End Property

Friend Property Get ErrorCorrectionLevel() As ErrorCorrectionLevel
    ErrorCorrectionLevel = m_errorCorrectionLevel
End Property

Friend Property Get Encoding() As Encoding
    Set Encoding = m_encoding
End Property

Public Property Get NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
' [Attribute NewEnum.VB_UserMemId = -4]
    Set NewEnum = m_items.[_NewEnum]
End Property

Private Function Add() As Symbol
    Set m_currSymbol = New Symbol
    Call m_currSymbol.Init(Me)
    Call m_items.Add(m_currSymbol)

    Set Add = m_currSymbol
End Function

Public Sub AppendText(ByVal s As String)
    If Len(s) = 0 Then Call Err.Raise(5)

    Dim oldMode As EncodingMode
    Dim newMode As EncodingMode

    Dim c As String

    Dim i As Long
    For i = 1 To Len(s)
        oldMode = m_currSymbol.CurrentEncodingMode

        Select Case oldMode
            Case EncodingMode.UNKNOWN
                newMode = SelectInitialMode(s, i)
            Case EncodingMode.NUMERIC
                newMode = SelectModeWhileInNumeric(s, i)
            Case EncodingMode.ALPHA_NUMERIC
                newMode = SelectModeWhileInAlphanumeric(s, i)
            Case EncodingMode.EIGHT_BIT_BYTE
                newMode = SelectModeWhileInByte(s, i)
            Case EncodingMode.KANJI
                newMode = SelectInitialMode(s, i)
            Case Else
                Call Err.Raise(51)
        End Select

        c = Mid$(s, i, 1)

        If newMode <> oldMode Then
            If Not m_currSymbol.TrySetEncodingMode(newMode, c) Then
                If Not m_structuredAppend Or m_items.Count = 16 Then
                    Call Err.Raise(6, Description:="String too long")
                End If

                Call Add
                newMode = SelectInitialMode(s, i)
                Call m_currSymbol.TrySetEncodingMode(newMode, c)
            End If
        End If

        If Not m_currSymbol.TryAppend(c) Then
            If Not m_structuredAppend Or m_items.Count = 16 Then
                Call Err.Raise(6, Description:="String too long")
            End If

            Call Add
            newMode = SelectInitialMode(s, i)
            Call m_currSymbol.TrySetEncodingMode(newMode, c)
            Call m_currSymbol.TryAppend(c)
        End If
    Next
End Sub

Friend Sub UpdateParity(ByVal c As String)
    Dim charBytes() As Byte
    charBytes = m_encoding.GetBytes(c)

    Dim i As Long
    For i = 0 To UBound(charBytes)
        m_parity = m_parity Xor charBytes(i)
    Next
End Sub

Private Function SelectInitialMode( _
    ByRef s As String, ByVal startIndex As Long) As EncodingMode

    If Not (m_encKanji Is Nothing) Then
        If m_encKanji.InSubset(Mid$(s, startIndex, 1)) Then
            SelectInitialMode = EncodingMode.KANJI
            Exit Function
        End If
    End If

    If m_encByte.InExclusiveSubset(Mid$(s, startIndex, 1)) Then
        SelectInitialMode = EncodingMode.EIGHT_BIT_BYTE
        Exit Function
    End If

    If m_encAlpha.InExclusiveSubset(Mid$(s, startIndex, 1)) Then
        SelectInitialMode = SelectModeWhenInitialDataAlphaNumeric(s, startIndex)
        Exit Function
    End If

    If m_encNum.InSubset(Mid$(s, startIndex, 1)) Then
        SelectInitialMode = SelectModeWhenInitialDataNumeric(s, startIndex)
        Exit Function
    End If

    Call Err.Raise(51)
End Function

Private Function SelectModeWhenInitialDataAlphaNumeric( _
    ByRef s As String, ByVal startIndex As Long) As EncodingMode

    Dim cnt As Long
    cnt = 0

    Dim i As Long
    For i = startIndex To Len(s)
        If m_encAlpha.InExclusiveSubset(Mid$(s, i, 1)) Then
            cnt = cnt + 1
        Else
            Exit For
        End If
    Next

    Dim flg As Boolean

    Select Case m_currSymbol.Version
        Case 1 To 9
            flg = cnt < 6
        Case 10 To 26
            flg = cnt < 7
        Case 27 To 40
            flg = cnt < 8
        Case Else
            Call Err.Raise(51)
    End Select

    If flg Then
        If (startIndex + cnt) <= Len(s) Then
            If m_encByte.InSubset(Mid$(s, startIndex + cnt, 1)) Then
                SelectModeWhenInitialDataAlphaNumeric = EncodingMode.EIGHT_BIT_BYTE
                Exit Function
            End If
        End If
    End If

    SelectModeWhenInitialDataAlphaNumeric = EncodingMode.ALPHA_NUMERIC
End Function

Private Function SelectModeWhenInitialDataNumeric( _
    ByRef s As String, ByVal startIndex As Long) As EncodingMode

    Dim cnt As Long
    cnt = 0

    Dim i As Long
    For i = startIndex To Len(s)
        If m_encNum.InSubset(Mid$(s, i, 1)) Then
            cnt = cnt + 1
        Else
            Exit For
        End If
    Next

    Dim flg As Boolean

    Select Case m_currSymbol.Version
        Case 1 To 9
            flg = cnt < 4
        Case 10 To 26
            flg = cnt < 4
        Case 27 To 40
            flg = cnt < 5
        Case Else
            Call Err.Raise(51)
    End Select

    If flg Then
        If (startIndex + cnt) <= Len(s) Then
            If m_encByte.InExclusiveSubset(Mid$(s, startIndex + cnt, 1)) Then
                SelectModeWhenInitialDataNumeric = EncodingMode.EIGHT_BIT_BYTE
                Exit Function
            End If
        End If
    End If

    Select Case m_currSymbol.Version
        Case 1 To 9
            flg = cnt < 7
        Case 10 To 26
            flg = cnt < 8
        Case 27 To 40
            flg = cnt < 9
        Case Else
            Call Err.Raise(51)
    End Select

    If flg Then
        If (startIndex + cnt) <= Len(s) Then
            If m_encAlpha.InExclusiveSubset(Mid$(s, startIndex + cnt, 1)) Then
                SelectModeWhenInitialDataNumeric = EncodingMode.ALPHA_NUMERIC
                Exit Function
            End If
        End If
    End If

    SelectModeWhenInitialDataNumeric = EncodingMode.NUMERIC
End Function

Private Function SelectModeWhileInNumeric( _
    ByRef s As String, ByVal startIndex As Long) As EncodingMode

    If Not (m_encKanji Is Nothing) Then
        If m_encKanji.InSubset(Mid$(s, startIndex, 1)) Then
            SelectModeWhileInNumeric = EncodingMode.KANJI
            Exit Function
        End If
    End If

    If m_encByte.InExclusiveSubset(Mid$(s, startIndex, 1)) Then
        SelectModeWhileInNumeric = EncodingMode.EIGHT_BIT_BYTE
        Exit Function
    End If

    If m_encAlpha.InExclusiveSubset(Mid$(s, startIndex, 1)) Then
        SelectModeWhileInNumeric = EncodingMode.ALPHA_NUMERIC
        Exit Function
    End If

    SelectModeWhileInNumeric = EncodingMode.NUMERIC
End Function

Private Function SelectModeWhileInAlphanumeric( _
    ByRef s As String, ByVal startIndex As Long) As EncodingMode

    If Not (m_encKanji Is Nothing) Then
        If m_encKanji.InSubset(Mid$(s, startIndex, 1)) Then
            SelectModeWhileInAlphanumeric = EncodingMode.KANJI
            Exit Function
        End If
    End If

    If m_encByte.InExclusiveSubset(Mid$(s, startIndex, 1)) Then
        SelectModeWhileInAlphanumeric = EncodingMode.EIGHT_BIT_BYTE
        Exit Function
    End If

    If MustChangeAlphanumericToNumeric(s, startIndex) Then
        SelectModeWhileInAlphanumeric = EncodingMode.NUMERIC
        Exit Function
    End If

    SelectModeWhileInAlphanumeric = EncodingMode.ALPHA_NUMERIC
End Function

Private Function MustChangeAlphanumericToNumeric( _
    ByRef s As String, ByVal startIndex As Long) As Boolean

    Dim ret As Boolean
    ret = False

    Dim cnt As Long
    cnt = 0

    Dim i As Long
    For i = startIndex To Len(s)
        If Not m_encAlpha.InSubset(Mid$(s, i, 1)) Then
            Exit For
        End If

        If m_encNum.InSubset(Mid$(s, i, 1)) Then
            cnt = cnt + 1
        Else
            ret = True
            Exit For
        End If
    Next

    If ret Then
        Select Case m_currSymbol.Version
            Case 1 To 9
                ret = cnt >= 13
            Case 10 To 26
                ret = cnt >= 15
            Case 27 To 40
                ret = cnt >= 17
            Case Else
                Call Err.Raise(51)
        End Select
    End If

    MustChangeAlphanumericToNumeric = ret
End Function

Private Function SelectModeWhileInByte( _
    ByRef s As String, ByVal startIndex As Long) As EncodingMode

    If Not (m_encKanji Is Nothing) Then
        If m_encKanji.InSubset(Mid$(s, startIndex, 1)) Then
            SelectModeWhileInByte = EncodingMode.KANJI
            Exit Function
        End If
    End If

    If MustChangeByteToNumeric(s, startIndex) Then
        SelectModeWhileInByte = EncodingMode.NUMERIC
        Exit Function
    End If

    If MustChangeByteToAlphanumeric(s, startIndex) Then
        SelectModeWhileInByte = EncodingMode.ALPHA_NUMERIC
        Exit Function
    End If

    SelectModeWhileInByte = EncodingMode.EIGHT_BIT_BYTE
End Function

Private Function MustChangeByteToNumeric( _
    ByRef s As String, ByVal startIndex As Long) As Boolean

    Dim ret As Boolean
    ret = False

    Dim cnt As Long
    cnt = 0

    Dim i As Long
    For i = startIndex To Len(s)
        If Not m_encByte.InSubset(Mid$(s, i, 1)) Then
            Exit For
        End If

        If m_encNum.InSubset(Mid$(s, i, 1)) Then
            cnt = cnt + 1
        ElseIf m_encByte.InExclusiveSubset(Mid$(s, i, 1)) Then
            ret = True
            Exit For
        Else
            Exit For
        End If
    Next

    If ret Then
        Select Case m_currSymbol.Version
            Case 1 To 9
                ret = cnt >= 6
            Case 10 To 26
                ret = cnt >= 8
            Case 27 To 40
                ret = cnt >= 9
            Case Else
                Call Err.Raise(51)
        End Select
    End If

    MustChangeByteToNumeric = ret
End Function

Private Function MustChangeByteToAlphanumeric( _
    ByRef s As String, ByVal startIndex As Long) As Boolean

    Dim ret As Boolean
    ret = False

    Dim cnt As Long
    cnt = 0

    Dim i As Long
    For i = startIndex To Len(s)
        If Not m_encByte.InSubset(Mid$(s, i, 1)) Then
            Exit For
        End If

        If m_encAlpha.InExclusiveSubset(Mid$(s, i, 1)) Then
            cnt = cnt + 1
        ElseIf m_encByte.InExclusiveSubset(Mid$(s, i, 1)) Then
            ret = True
            Exit For
        Else
            Exit For
        End If
    Next

    If ret Then
        Select Case m_currSymbol.Version
            Case 1 To 9
                ret = cnt >= 11
            Case 10 To 26
                ret = cnt >= 15
            Case 27 To 40
                ret = cnt >= 16
            Case Else
                Call Err.Raise(51)
        End Select
    End If

    MustChangeByteToAlphanumeric = ret
End Function
