Option Explicit
' READ-ONLY. Dumps menu labels and grid pane contents in /IWFND/GW_CLIENT.
Dim sapGuiAuto, app, conn, sess, i, j, m, sub_, g, r, c, cols, n
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

WScript.Echo "=== MENUS ==="
For i = 0 To 5
  On Error Resume Next
  Set m = sess.FindById("wnd[0]/mbar/menu[" & i & "]")
  If Err.Number <> 0 Then Err.Clear : On Error GoTo 0 : Exit For
  WScript.Echo "menu[" & i & "] = " & m.Text
  For j = 0 To 20
    Set sub_ = Nothing
    Set sub_ = sess.FindById("wnd[0]/mbar/menu[" & i & "]/menu[" & j & "]")
    If Err.Number <> 0 Then Err.Clear : Exit For
    WScript.Echo "   menu[" & i & "]/menu[" & j & "] = " & sub_.Text
  Next
  On Error GoTo 0
Next

WScript.Echo "=== GRID PANES ==="
For n = 0 To 1
  On Error Resume Next
  Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[" & n & "]/shell")
  If Err.Number <> 0 Then Err.Clear : On Error GoTo 0 : WScript.Echo "grid " & n & " absent" : Exit For
  WScript.Echo "GRID[" & n & "] Title=" & g.Title & " RowCount=" & g.RowCount
  Set cols = g.ColumnOrder
  Dim colline : colline = ""
  For c = 0 To cols.Count - 1
    colline = colline & cols(c) & " "
  Next
  WScript.Echo "GRID[" & n & "] COLS=" & colline
  For r = 0 To g.RowCount - 1
    If r > 40 Then Exit For
    Dim line : line = ""
    For c = 0 To cols.Count - 1
      line = line & cols(c) & "=" & g.GetCellValue(CLng(r), cols(c)) & " | "
    Next
    WScript.Echo "GRID[" & n & "] ROW" & r & ": " & line
  Next
  On Error GoTo 0
Next
