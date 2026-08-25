Option Explicit
Dim sapGuiAuto, app, conn, sess, g, elapsed
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[1]/shell")
WScript.Echo "before windows=" & sess.Children.Count & " title=" & g.Title
On Error Resume Next
g.PressToolbarButton "COPY_BODY"
If Err.Number <> 0 Then WScript.Echo "PressToolbarButton ERR: " & Err.Description : Err.Clear
On Error GoTo 0
Ready 60000
WScript.Echo "after windows=" & sess.Children.Count
Dim i
For i = 1 To sess.Children.Count - 1
  WScript.Echo "MODAL wnd[" & i & "] = " & sess.Children.Item(CLng(i)).Text
Next
WScript.Echo "sbar=" & sess.FindById("wnd[0]/sbar").Text
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
