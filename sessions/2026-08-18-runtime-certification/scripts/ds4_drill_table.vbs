Option Explicit
' Double-click a label at <col>,<row> on the SE37 result screen and dump the table
' that opens, paging through it. Usage: ds4_drill_table.vbs <col> <row> [maxRows]
Dim app, sess, i, j, conn, s, found, elapsed, c, r, maxRows, u, k, ch, sid, seen, lastTop

c = WScript.Arguments(0) : r = WScript.Arguments(1)
maxRows = 2000
If WScript.Arguments.Count > 2 Then maxRows = CLng(WScript.Arguments(2))

Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_200" : WScript.Quit 9

sess.FindById("wnd[0]/usr/lbl[" & c & "," & r & "]").SetFocus
sess.FindById("wnd[0]/usr/lbl[" & c & "," & r & "]").CaretPosition = 3
sess.FindById("wnd[0]").SendVKey 2
Ready 120000

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text

Dim g
Set g = FindGrid(sess.FindById("wnd[0]/usr"), 0)
If Not g Is Nothing Then
  Dim cols, rr, cc, line, v, n
  Set cols = g.ColumnOrder
  WScript.Echo "GRID|rows=" & g.RowCount
  n = g.RowCount - 1
  If n > maxRows Then n = maxRows
  For rr = 0 To n
    If rr Mod 20 = 0 Then
      On Error Resume Next
      g.FirstVisibleRow = rr
      Err.Clear
      On Error GoTo 0
    End If
    line = ""
    For cc = 0 To cols.Count - 1
      v = ""
      On Error Resume Next
      v = g.GetCellValue(CLng(rr), cols(cc))
      Err.Clear
      On Error GoTo 0
      line = line & v
    Next
    WScript.Echo "L" & (rr+1) & "|" & line
  Next
Else
  ' classic list — page with Page Down and read labels
  seen = 0 : lastTop = ""
  Do While seen < maxRows
    Set u = sess.FindById("wnd[0]/usr")
    Dim buf : buf = ""
    For k = 0 To u.Children.Count - 1
      Set ch = u.Children.Item(CLng(k))
      On Error Resume Next
      sid = ch.Id
      If ch.Type = "GuiTextField" Or ch.Type = "GuiCTextField" Or ch.Type = "GuiLabel" Then
        If Len(ch.Text) > 0 Then buf = buf & ch.Text & vbLf
      End If
      Err.Clear
      On Error GoTo 0
    Next
    If buf = lastTop Then Exit Do
    lastTop = buf
    WScript.Echo buf
    seen = seen + 30
    sess.FindById("wnd[0]").SendVKey 82   ' Page Down
    Ready 30000
  Loop
End If

Function FindGrid(node, depth)
  Dim kk, child, res
  Set FindGrid = Nothing
  If depth > 8 Then Exit Function
  On Error Resume Next
  If node.Type = "GuiShell" Then
    If node.SubType = "GridView" Then Set FindGrid = node : Exit Function
  End If
  If node.ContainerType = True Then
    For kk = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(kk))
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
  WScript.Sleep 900
End Sub
