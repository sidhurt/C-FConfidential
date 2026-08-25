Option Explicit
' READ-ONLY: open SE37 for a function module and trigger the Where-Used List.
' Stage 1 dumps the scope dialog so it can be inspected before anything is confirmed.
' Stage 2 (arg 2 = "GO") accepts the scope dialog and dumps the result list.
Dim sapGuiAuto, app, conn, sess, fm, mode, elapsed, i, k, ch, u, g

If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|<FM> [GO]" : WScript.Quit 1
fm = UCase(WScript.Arguments(0))
mode = ""
If WScript.Arguments.Count > 1 Then mode = UCase(WScript.Arguments(1))

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

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = fm
Ready 5000
sess.FindById("wnd[0]/tbar[1]/btn[39]").Press   ' Where-Used List
Ready 60000

If sess.Children.Count > 1 Then
  WScript.Echo "DIALOG|" & sess.FindById("wnd[1]").Text
  If mode <> "GO" Then
    Set u = sess.FindById("wnd[1]/usr")
    For k = 0 To u.Children.Count - 1
      Set ch = u.Children.Item(CLng(k))
      On Error Resume Next
      If Len(Trim(ch.Text)) > 0 Or ch.Type = "GuiCheckBox" Then
        WScript.Echo "  [" & ch.Type & "] " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[1]/usr/", "") & _
          " text='" & ch.Text & "' sel='" & ch.Selected & "'"
      End If
      Err.Clear
      On Error GoTo 0
    Next
    WScript.Echo "STOPPED|scope dialog left open for inspection; rerun with GO to accept"
    WScript.Quit 0
  End If
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
  Dim cols, r, c, line
  Set cols = g.ColumnOrder
  WScript.Echo "GRID|rows=" & g.RowCount & "|cols=" & cols.Count
  line = ""
  For c = 0 To cols.Count - 1
    line = line & cols(c) & vbTab
  Next
  WScript.Echo "HDR|" & line
  For r = 0 To g.RowCount - 1
    If r > 150 Then Exit For
    If g.VisibleRowCount > 0 And (r Mod g.VisibleRowCount) = 0 Then
      On Error Resume Next
      g.FirstVisibleRow = r
      Err.Clear
      On Error GoTo 0
    End If
    line = ""
    For c = 0 To cols.Count - 1
      Dim v
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
  WScript.Sleep 700
End Sub
