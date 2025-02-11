Attribute VB_Name = "TimingPattern"
Option Private Module
Option Explicit

Private Const VAL As Long = Values.TIMING_PTN

Public Sub Place(ByRef moduleMatrix() As Variant)
    Dim i As Long
    Dim v As Long
    For i = 8 To UBound(moduleMatrix) - 8
        v = IIf(i Mod 2 = 0, VAL, -VAL)
        moduleMatrix(6)(i) = v
        moduleMatrix(i)(6) = v
    Next
End Sub
