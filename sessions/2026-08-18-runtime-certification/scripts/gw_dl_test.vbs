Option Explicit
Dim sapGuiAuto, app, conn, sess, g0, elapsed, outDir
outDir = WScript.Arguments(0)
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
Set g0 = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[0]/shell")
On Error Resume Next
g0.PressToolbarButton "CHECK_XML"
If Err.Number <> 0 Then WScript.Echo "CHECK_XML ERR " & Err.Description : Err.Clear
On Error GoTo 0
Ready 60000
WScript.Echo "after CHECK_XML windows=" & sess.Children.Count & " sbar=" & sess.FindById("wnd[0]/sbar").Text
Dim guard : guard = 0
Do While sess.Children.Count > 1 And guard < 5
  WScript.Echo "  modal: " & sess.FindById("wnd[1]").Text
  sess.FindById("wnd[1]").SendVKey 0
  Ready 10000
  guard = guard + 1
Loop
sess.FindById("wnd[0]/mbar/menu[0]/menu[0]").Select
Ready 30000
If sess.Children.Count > 1 And sess.FindById("wnd[1]").Text = "Save File" Then
  sess.FindById("wnd[1]/usr/ctxtDY_PATH").Text = outDir & "\"
  sess.FindById("wnd[1]/usr/ctxtDY_FILENAME").Text = "DLTEST_raw.xml"
  sess.FindById("wnd[1]/tbar[0]/btn[11]").Press
  Ready 120000
  WScript.Echo "downloaded"
Else
  WScript.Echo "no save dialog"
End If
guard = 0
Do While sess.Children.Count > 1 And guard < 5
  sess.FindById("wnd[" & (sess.Children.Count-1) & "]").SendVKey 12
  Ready 10000
  guard = guard + 1
Loop
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
