Option Explicit
' STEP 5 (input only, no execution): set POHEADERX-DOC_TYPE = X, return to the
' test screen, and report the complete populated input state. Does not press F8.
Dim sapGuiAuto, app, conn, sess, elapsed

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "ABORT|WRONG_SYSTEM_OR_CLIENT|" & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_ALREADY_OPEN|" & sess.FindById("wnd[1]").Text
  WScript.Quit 10
End If
If InStr(sess.FindById("wnd[0]").Text, "POHEADERX") = 0 Then
  WScript.Echo "ABORT|UNEXPECTED_SCREEN|" & sess.FindById("wnd[0]").Text
  WScript.Quit 11
End If

sess.FindById("wnd[0]/usr/txt[5,3]").Text = "X"
Ready 15000
WScript.Echo "SET|wnd[0]/usr/txt[5,3]|POHEADERX-DOC_TYPE|X|readback='" & _
  sess.FindById("wnd[0]/usr/txt[5,3]").Text & "'"

sess.FindById("wnd[0]").SendVKey 3
Ready 60000
If sess.Children.Count > 1 Then
  WScript.Echo "STOP|UNEXPECTED_MODAL_AFTER_BACK|" & sess.FindById("wnd[1]").Text
  WScript.Quit 12
End If

WScript.Echo "AFTER_BACK|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "=== POPULATED INPUT STATE (pre-execution) ==="
WScript.Echo "POHEADER  row value  = '" & sess.FindById("wnd[0]/usr/lbl[37,9]").Text & "'"
WScript.Echo "POHEADERX row value  = '" & sess.FindById("wnd[0]/usr/lbl[37,10]").Text & "'"
WScript.Echo "TESTRUN   txt[34,12] = '" & sess.FindById("wnd[0]/usr/txt[34,12]").Text & "'"
WScript.Echo "MEMORY_UNCOMPLETE txt[34,13] = '" & sess.FindById("wnd[0]/usr/txt[34,13]").Text & "'"
WScript.Echo "MEMORY_COMPLETE   txt[34,14] = '" & sess.FindById("wnd[0]/usr/txt[34,14]").Text & "'"
WScript.Echo "WINDOWS|" & sess.Children.Count
WScript.Echo "NOTE|nothing executed; F8 not pressed"

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 700
End Sub
