Attribute VB_Name = "MaskingPenaltyScore"
Option Private Module
Option Explicit

Public Function CalcTotal(ByRef moduleMatrix() As Variant) As Long
    Dim total As Long
    total = 0

    Dim penaltyScore As Long
    penaltyScore = CalcAdjacentModulesInSameColor(moduleMatrix)
    total = total + penaltyScore

    penaltyScore = CalcBlockOfModulesInSameColor(moduleMatrix)
    total = total + penaltyScore

    penaltyScore = CalcModuleRatio(moduleMatrix)
    total = total + penaltyScore

    penaltyScore = CalcProportionOfDarkModules(moduleMatrix)
    total = total + penaltyScore

    CalcTotal = total
End Function

Private Function CalcAdjacentModulesInSameColor(ByRef moduleMatrix() As Variant) As Long
    Dim penaltyScore As Long
    penaltyScore = 0

    penaltyScore = penaltyScore + CalcAdjacentModulesInRowInSameColor(moduleMatrix)
    penaltyScore = penaltyScore + CalcAdjacentModulesInRowInSameColor(ArrayUtil.Rotate90(moduleMatrix))

    CalcAdjacentModulesInSameColor = penaltyScore
End Function

Private Function CalcAdjacentModulesInRowInSameColor(ByRef moduleMatrix() As Variant) As Long
    Dim penaltyScore As Long
    penaltyScore = 0

    Dim rowArray As Variant
    Dim i As Long
    Dim cnt As Long
    For Each rowArray In moduleMatrix
        cnt = 1

        For i = 0 To UBound(rowArray) - 1
            If Values.IsDark(rowArray(i)) = Values.IsDark(rowArray(i + 1)) Then
                cnt = cnt + 1
            Else
                If cnt >= 5 Then
                    penaltyScore = penaltyScore + (3 + (cnt - 5))
                End If

                cnt = 1
            End If
        Next

        If cnt >= 5 Then
            penaltyScore = penaltyScore + (3 + (cnt - 5))
        End If
    Next

    CalcAdjacentModulesInRowInSameColor = penaltyScore
End Function

Private Function CalcBlockOfModulesInSameColor(ByRef moduleMatrix() As Variant) As Long
    Dim penaltyScore As Long
    Dim temp    As Boolean

    Dim r As Long
    Dim c As Long
    For r = 0 To UBound(moduleMatrix) - 1
        For c = 0 To UBound(moduleMatrix(r)) - 1
            temp = Values.IsDark(moduleMatrix(r)(c))

            If (Values.IsDark(moduleMatrix(r + 0)(c + 1)) = temp) And _
               (Values.IsDark(moduleMatrix(r + 1)(c + 0)) = temp) And _
               (Values.IsDark(moduleMatrix(r + 1)(c + 1)) = temp) Then
                penaltyScore = penaltyScore + 3
            End If
        Next
    Next

    CalcBlockOfModulesInSameColor = penaltyScore
End Function

Private Function CalcModuleRatio(ByRef moduleMatrix() As Variant) As Long
    Dim moduleMatrixTemp() As Variant
    moduleMatrixTemp = QuietZone.Place(moduleMatrix)

    Dim penaltyScore As Long
    penaltyScore = 0

    penaltyScore = penaltyScore + CalcModuleRatioInRow(moduleMatrixTemp)
    penaltyScore = penaltyScore + CalcModuleRatioInRow(ArrayUtil.Rotate90(moduleMatrixTemp))

    CalcModuleRatio = penaltyScore
End Function

Private Function CalcModuleRatioInRow(ByRef moduleMatrix() As Variant) As Long
    Dim penaltyScore As Long

    Dim ratio3Ranges As Collection

    Dim ratio1 As Long
    Dim ratio3 As Long
    Dim ratio4 As Long

    Dim cnt    As Long
    Dim impose As Boolean

    Dim rowArray As Variant
    Dim rng As Variant
    Dim i As Long
    For Each rowArray In moduleMatrix
        Set ratio3Ranges = GetRatio3Ranges(rowArray)

        For Each rng In ratio3Ranges
            ratio3 = rng(1) + 1 - rng(0)
            ratio1 = ratio3 \ 3
            ratio4 = ratio1 * 4
            impose = False

            i = rng(0) - 1

            ' light ratio 1
            cnt = 0
            Do While i >= 0
                If Values.IsDark(rowArray(i)) Then Exit Do

                cnt = cnt + 1
                i = i - 1
            Loop

            If cnt <> ratio1 Then GoTo Continue

            ' dark ratio 1
            cnt = 0
            Do While i >= 0
                If Not Values.IsDark(rowArray(i)) Then Exit Do

                cnt = cnt + 1
                i = i - 1
            Loop

            If cnt <> ratio1 Then GoTo Continue

            ' light ratio 4
            cnt = 0
            Do While i >= 0
                If Values.IsDark(rowArray(i)) Then Exit Do

                cnt = cnt + 1
                i = i - 1
            Loop

            If cnt >= ratio4 Then
                impose = True
            End If

            i = rng(1) + 1

            ' light ratio 1
            cnt = 0
            Do While i <= UBound(rowArray)
                If Values.IsDark(rowArray(i)) Then Exit Do

                cnt = cnt + 1
                i = i + 1
            Loop

            If cnt <> ratio1 Then GoTo Continue

            ' dark ratio 1
            cnt = 0
            Do While i <= UBound(rowArray)
                If Not Values.IsDark(rowArray(i)) Then Exit Do

                cnt = cnt + 1
                i = i + 1
            Loop

            If cnt <> ratio1 Then GoTo Continue

            ' light ratio 4
            cnt = 0
            Do While i <= UBound(rowArray)
                If Values.IsDark(rowArray(i)) Then Exit Do

                cnt = cnt + 1
                i = i + 1
            Loop

            If cnt >= ratio4 Then
                impose = True
            End If

            If impose Then
                penaltyScore = penaltyScore + 40
            End If
Continue:
        Next
    Next

    CalcModuleRatioInRow = penaltyScore
End Function

Private Function GetRatio3Ranges(ByRef arg As Variant) As Collection
    Dim ret As New Collection

    Dim s As Long

    Dim i As Long
    For i = 1 To UBound(arg) - 1
        If Values.IsDark(arg(i)) Then
            If Not Values.IsDark(arg(i - 1)) Then
                s = i
            End If

            If Not Values.IsDark(arg(i + 1)) Then
                If (i + 1 - s) Mod 3 = 0 Then
                    Call ret.Add(Array(s, i))
                End If
            End If
        End If
    Next

    Set GetRatio3Ranges = ret
End Function

Private Function CalcProportionOfDarkModules(ByRef moduleMatrix() As Variant) As Long
    Dim darkCount As Long

    Dim rowArray As Variant
    Dim v As Variant
    For Each rowArray In moduleMatrix
        For Each v In rowArray
            If Values.IsDark(v) Then
                darkCount = darkCount + 1
            End If
        Next
    Next

    Dim numModules As Double
    numModules = (UBound(moduleMatrix) + 1) ^ 2

    Dim k As Double
    k = darkCount / numModules * 100
    k = Abs(k - 50)
    k = Int(k / 5)
    Dim penaltyScore As Long
    penaltyScore = CLng(k) * 10

    CalcProportionOfDarkModules = penaltyScore
End Function
