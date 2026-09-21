' Include file: ApplyLayout sess, "COL1,COL2,..."  (Change Layout dialog must be reachable via wnd[0]/tbar[1]/btn[32])
Function ApplyLayout(sess, wantedCsv)
  Dim base, shown, hidden, wanted, i, sel, cnt, name, dict
  ApplyLayout = -1
  If sess.Children.Count < 2 Then sess.FindById("wnd[0]/tbar[1]/btn[32]").Press : LReady sess
  If sess.Children.Count < 2 Then Exit Function
  If sess.FindById("wnd[1]").Text <> "Change Layout" Then Exit Function
  base = "wnd[1]/usr/tabsG_TS_ALV/tabpALV_M_R1/ssubSUB_CONFIGURATION:SAPLSALV_CUL_COLUMN_SELECTION:0620/"
  Set shown = sess.FindById(base & "cntlCONTAINER2_LAYO/shellcont/shell")
  If shown.RowCount > 0 Then
    shown.SelectAll
    sess.FindById(base & "btnAPP_FL_SING").Press : LReady sess
  End If
  Set hidden = sess.FindById(base & "cntlCONTAINER1_LAYO/shellcont/shell")
  Set dict = CreateObject("Scripting.Dictionary")
  For Each name In Split(UCase(wantedCsv), ",") : dict(Trim(name)) = True : Next
  sel = "" : cnt = 0
  For i = 0 To hidden.RowCount - 1
    If i Mod 20 = 0 Then On Error Resume Next : hidden.FirstVisibleRow = i : Err.Clear : On Error GoTo 0
    name = UCase(Trim(hidden.GetCellValue(i, "SELTEXT")))
    If dict.Exists(name) Then
      If Len(sel) > 0 Then sel = sel & ","
      sel = sel & i : cnt = cnt + 1
    End If
  Next
  If cnt = 0 Then Exit Function
  hidden.SelectedRows = sel
  sess.FindById(base & "btnAPP_WL_SING").Press : LReady sess
  ApplyLayout = sess.FindById(base & "cntlCONTAINER2_LAYO/shellcont/shell").RowCount
  sess.FindById("wnd[1]/tbar[0]/btn[0]").Press : LReady sess
End Function
Sub LReady(sess)
  Dim e : e = 0
  Do While sess.Busy And e < 120000 : WScript.Sleep 200 : e = e + 200 : Loop
  WScript.Sleep 500
End Sub
