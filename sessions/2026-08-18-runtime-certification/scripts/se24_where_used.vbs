Option Explicit
' READ-ONLY: full-scope Where-Used for a global class via SE24.
Dim sapGuiAuto, app, conn, sess, cls, elapsed, k, ch, u, g, cols, r, c, line, v

If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|<CLASS>" : WScript.Quit 1
cls = UCase(WScript.Arguments(0))

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE24"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtSEOCLASS-CLSNAME").Text = cls
Ready 5000
sess.FindById("wnd[0]/tbar[1]/btn[39]").Press   ' Where-Used List
Ready 90000

If sess.Children.Count > 1 Then
  If InStr(sess.FindById("wnd[1]").Text, "Class") = 1 Or InStr(sess.FindById("wnd[1]").Text, cls) > 0 Then
    WScript.Echo "SCOPE|" & sess.FindById("wnd[1]").Text & "|Select All + Continue"
    On Error Resume Next
    sess.FindById("wnd[1]/tbar[0]/btn[7]").Press
    Err.Clear
    On Error GoTo 0
    Ready 30000
    sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
    Ready 600000
  Else
    WScript.Echo "ABORT|UNEXPECTED_MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 12
  End If
End If

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_SEARCH|" & sess.FindById("wnd[1]").Text : WScript.Quit 13
End If

WScript.Echo "CLASS|" & cls
WScript.Echo "RESULT_TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text

Set g = FindGrid(sess.FindById("wnd[0]/usr"), 0)
If g Is Nothing Then
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
  WScript.Echo "GRID|rows=" & g.RowCount
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
