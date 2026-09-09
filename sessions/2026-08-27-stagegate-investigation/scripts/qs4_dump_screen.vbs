Option Explicit
' READ-ONLY QS4/700: dump the CURRENT screen - control tree, tabs, grids, editors. Presses nothing.
Dim app, conn, s, sess, found, i, j
Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_QS4_700" : WScript.Quit 9
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text & "|TCODE=" & sess.Info.Transaction & "|PROG=" & sess.Info.Program & "|SCR=" & sess.Info.ScreenNumber
WScript.Echo "WINDOWS|" & sess.Children.Count
For i = 1 To sess.Children.Count - 1
  WScript.Echo "MODAL[" & i & "]|" & sess.Children.Item(CLng(i)).Text
Next
Walk sess.FindById("wnd[0]/usr"), 0

Function SafeSub(node)
  Dim v
  SafeSub = ""
  On Error Resume Next
  v = node.SubType
  If Err.Number = 0 Then SafeSub = v
  Err.Clear
  On Error GoTo 0
End Function

Sub Walk(node, depth)
  Dim n, child, ty, st, tx, ln, g, cols, r, c, line, v
  If depth > 8 Then Exit Sub
  On Error Resume Next
  ty = "" : ty = node.Type
  If Len(ty) = 0 Then Err.Clear : Exit Sub
  st = SafeSub(node)
  tx = ""
  If ty = "GuiLabel" Or ty = "GuiButton" Or ty = "GuiTab" Or ty = "GuiTitlebar" Then
    tx = " '" & node.Text & "'"
    Err.Clear
  End If
  If ty = "GuiTextedit" Or st = "TextEdit" Then
    ln = -1 : ln = Len(node.Text) : Err.Clear
    tx = tx & " [TEXTLEN=" & ln & "]"
  End If
  WScript.Echo Space(depth*2) & "[" & ty & "/" & st & "] " & Replace(node.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & tx
  Err.Clear

  If st = "GridView" Then
    Set g = node
    WScript.Echo Space(depth*2) & "  GRID Title=" & g.Title & " rows=" & g.RowCount
    Set cols = g.ColumnOrder
    line = ""
    For c = 0 To cols.Count - 1
      line = line & cols(c) & vbTab
    Next
    WScript.Echo Space(depth*2) & "  HDR|" & line
    For r = 0 To g.RowCount - 1
      If r > 80 Then Exit For
      If g.VisibleRowCount > 0 And (r Mod g.VisibleRowCount) = 0 Then g.FirstVisibleRow = r : Err.Clear
      line = ""
      For c = 0 To cols.Count - 1
        v = "" : v = g.GetCellValue(CLng(r), cols(c)) : Err.Clear
        line = line & v & vbTab
      Next
      WScript.Echo Space(depth*2) & "  ROW" & r & "|" & line
    Next
    Err.Clear
  End If

  Dim isC : isC = False
  isC = node.ContainerType
  Err.Clear
  If isC = True Then
    For n = 0 To node.Children.Count - 1
      Set child = Nothing
      Set child = node.Children.Item(CLng(n))
      If Err.Number = 0 And Not child Is Nothing Then Walk child, depth + 1
      Err.Clear
    Next
  End If
  On Error GoTo 0
End Sub
