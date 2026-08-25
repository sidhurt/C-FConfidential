Option Explicit
' Fill the GW_CLIENT "Add File" dialog with a local payload file and confirm.
' Usage: gw_load_body.vbs <directory> <filename>
Dim sapGuiAuto, app, conn, sess, elapsed, dir, fn, i

dir = WScript.Arguments(0)
fn  = WScript.Arguments(1)

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count < 2 Then WScript.Echo "ABORT|NO_DIALOG" : WScript.Quit 10
If sess.FindById("wnd[1]").Text <> "Save File" Then
  WScript.Echo "ABORT|UNEXPECTED_MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 11
End If

sess.FindById("wnd[1]/usr/ctxtDY_PATH").Text = dir
sess.FindById("wnd[1]/usr/ctxtDY_FILENAME").Text = fn
WScript.Echo "FILE|" & dir & fn
sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
Ready 60000

WScript.Echo "WINDOWS|" & sess.Children.Count
For i = 1 To sess.Children.Count - 1
  WScript.Echo "MODAL|" & sess.Children.Item(CLng(i)).Text
Next
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text

' report whether a body is now attached
On Error Resume Next
Dim g
Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[0]/shell")
If Err.Number = 0 Then
  WScript.Echo "REMOVE_FILE_enabled=" & g.GetToolbarButtonEnabled(CLng(9))
End If
Err.Clear
On Error GoTo 0

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 1000
End Sub
