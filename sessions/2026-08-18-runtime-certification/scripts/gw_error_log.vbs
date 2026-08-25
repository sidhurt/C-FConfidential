Option Explicit
' Press the ERROR_LOG button on the GW_CLIENT response grid and dump what appears.
Dim sapGuiAuto, app, conn, sess, elapsed, g, k, ch, u, i

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If

Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[1]/shell")
g.PressToolbarButton "ERROR_LOG"
Ready 120000

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "TCODE|" & sess.Info.Transaction
WScript.Echo "WINDOWS|" & sess.Children.Count
For i = 1 To sess.Children.Count - 1
  WScript.Echo "MODAL|" & sess.Children.Item(CLng(i)).Text
Next

Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If Len(Trim(ch.Text)) > 0 Then
    WScript.Echo "  [" & ch.Type & "] " & Mid(ch.Id, InStr(ch.Id, "/usr/") + 5) & " = '" & ch.Text & "'"
  End If
  Err.Clear
  On Error GoTo 0
Next

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 1200
End Sub
