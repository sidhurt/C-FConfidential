Option Explicit
Dim sapGuiAuto, app, conn, sess, g, i, n
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
For n = 0 To 1
  On Error Resume Next
  Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[" & n & "]/shell")
  WScript.Echo "=== GRID[" & n & "] " & g.Title & " toolbarButtonCount=" & g.ToolbarButtonCount
  For i = 0 To g.ToolbarButtonCount - 1
    WScript.Echo "  btn " & i & " | id='" & g.GetToolbarButtonId(CLng(i)) & "' | type=" & g.GetToolbarButtonType(CLng(i)) & " | text='" & g.GetToolbarButtonText(CLng(i)) & "' | tip='" & g.GetToolbarButtonTooltip(CLng(i)) & "' | enabled=" & g.GetToolbarButtonEnabled(CLng(i))
  Next
  Err.Clear
  On Error GoTo 0
Next
