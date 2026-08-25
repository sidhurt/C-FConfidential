Option Explicit
' READ-ONLY: accept an already-open SE37 Where-Used scope dialog (title must start with
' "Function Module:") and dump the resulting hit list. Refuses any other modal.
Dim sapGuiAuto, app, conn, sess, elapsed, k, ch, u, g, cols, r, c, line, v

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If

If sess.Children.Count > 1 Then
  If InStr(sess.FindById("wnd[1]").Text, "Function Module:") <> 1 Then
    WScript.Echo "ABORT|UNEXPECTED_MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
  End If
  WScript.Echo "ACCEPTING_SCOPE_DIALOG|" & sess.FindById("wnd[1]").Text
  sess.FindById("wnd[1]").SendVKey 0
  Ready 300000
End If

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_SEARCH|" & sess.FindById("wnd[1]").Text & "|left open"
  WScript.Quit 13
End If

WScript.Echo "RESULT_TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text

Set g = FindGrid(sess.FindById("wnd[0]/usr"), 0)
If g Is Nothing Then
  WScript.Echo "NO_GRID|dumping labels"
  Set u = sess.FindById("wnd[0]/usr")
  For k = 0 To u.Children.Count - 1
    Set ch = u.Children.Item(CLng(k))
    On Error Resume Next
    If Len(Trim(ch.Text)) > 0 Then WScript.Echo "  " & ch.Text
    Err.Clear
    On Error GoTo 0
  Next
Else
  Set cols = g.ColumnOrder
  WScript.Echo "GRID|rows=" & g.RowCount & "|cols=" & cols.Count
  line = ""
  For c = 0 To cols.Count - 1
    line = line & cols(c) & vbTab
  Next
  WScript.Echo "HDR|" & line
  For r = 0 To g.RowCount - 1
    If r > 200 Then Exit For
    If g.VisibleRowCount > 0 And (r Mod g.VisibleRowCount) = 0 Then
      On Error Resume Next
      g.FirstVisibleRow = r
      Err.Clear
      On Error GoTo 0
    End If
    line = ""
    For c = 0 To cols.Count - 1
      v = ""
      On Error Resume Next
      v = g.GetCellValue(CLng(r), cols(c))
      Err.Clear
      On Error GoTo 0
      line = line & v & vbTab
    Next
    WScript.Echo "ROW" & r & "|" & line
  Next
End If

Function FindGrid(node, depth)
  Dim k2, child, res
  Set FindGrid = Nothing
  If depth > 8 Then Exit Function
  On Error Resume Next
  If node.Type = "GuiShell" Then
    If node.SubType = "GridView" Then Set FindGrid = node : Exit Function
  End If
  If node.ContainerType = True Then
    For k2 = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k2))
      Set res = FindGrid(child, depth + 1)
      If Not res Is Nothing Then Set FindGrid = res : Exit Function
    Next
  End If
  On Error GoTo 0
End Function

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
