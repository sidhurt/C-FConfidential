Option Explicit
Dim sapGuiAuto, app, conn, sess, ed, sh, elapsed
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
Set ed = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[2]/shell")

WScript.Echo "probing accessors on pane2..."
On Error Resume Next
Dim t
t = ed.Text : WScript.Echo "  .Text -> '" & Left(t,60) & "' err=" & Err.Description : Err.Clear
t = ed.GetUnprotectedTextPart(0) : WScript.Echo "  .GetUnprotectedTextPart(0) len=" & Len(t) & " err=" & Err.Description : Err.Clear
WScript.Echo "  .ContextMenu try"
ed.SetFocus
Err.Clear
On Error GoTo 0

Set sh = CreateObject("WScript.Shell")
sh.AppActivate "SAP Gateway Client"
WScript.Sleep 800
sh.SendKeys "^a"
WScript.Sleep 400
sh.SendKeys "^c"
WScript.Sleep 1200
WScript.Echo "sendkeys done"
