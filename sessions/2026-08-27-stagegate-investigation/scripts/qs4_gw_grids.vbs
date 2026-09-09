Option Explicit
' READ-ONLY: dump /IWFND/GW_CLIENT request+response header grids and their toolbars.
Dim app, conn, s, sess, found, elapsed, i, j, p, g, r, c, cols, line, v, k, tt
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
WScript.Echo "TCODE|" & sess.Info.Transaction

For p = 0 To 1
  On Error Resume Next
  Set g = Nothing
  Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[" & p & "]/shell")
  If Err.Number <> 0 Or g Is Nothing Then
    WScript.Echo "GRID[" & p & "]|absent"
  Else
    WScript.Echo "GRID[" & p & "]|Title=" & g.Title & "|rows=" & g.RowCount
    Set cols = g.ColumnOrder
    line = ""
    For c = 0 To cols.Count - 1
      line = line & cols(c) & vbTab
    Next
    WScript.Echo "GRID[" & p & "]|HDR|" & line
    For r = 0 To g.RowCount - 1
      If r > 60 Then Exit For
      line = ""
      For c = 0 To cols.Count - 1
        v = "" : v = g.GetCellValue(CLng(r), cols(c)) : Err.Clear
        line = line & v & vbTab
      Next
      WScript.Echo "GRID[" & p & "]|ROW" & r & "|" & line
    Next
    For k = 0 To 25
      tt = "" : tt = g.GetToolbarButtonId(CLng(k))
      If Err.Number = 0 And Len(tt) > 0 Then
        WScript.Echo "GRID[" & p & "]|TB" & k & "|id=" & tt & "|tip=" & g.GetToolbarButtonTooltip(CLng(k)) & "|enabled=" & g.GetToolbarButtonEnabled(CLng(k))
      End If
      Err.Clear
    Next
  End If
  Err.Clear
  On Error GoTo 0
Next
