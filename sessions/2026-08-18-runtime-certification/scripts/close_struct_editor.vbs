Option Explicit
' Close an open SE37 "Structure Editor" modal only.  Refuses any other modal.
Dim sapGuiAuto, app, conn, sess, elapsed, guard

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If

guard = 0
Do While sess.Children.Count > 1 And guard < 6
  If InStr(sess.FindById("wnd[1]").Text, "Structure Editor") <> 1 Then
    WScript.Echo "STOP|unexpected modal: " & sess.FindById("wnd[1]").Text
    WScript.Quit 10
  End If
  WScript.Echo "closing: " & sess.FindById("wnd[1]").Text
  sess.FindById("wnd[1]").SendVKey 12
  Ready 30000
  guard = guard + 1
Loop

WScript.Echo "WINDOWS|" & sess.Children.Count & "|wnd0=" & sess.FindById("wnd[0]").Text

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 700
End Sub
