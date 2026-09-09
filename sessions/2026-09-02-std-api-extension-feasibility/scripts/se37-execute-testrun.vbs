Option Explicit
' Closes the entry modal, returns to the SE37 test screen, VERIFIES TESTRUN = 'X',
' and only then executes. Aborts hard if TESTRUN is not set.
' This is a TEST RUN only - the BAPI posts nothing and no COMMIT is issued.

Dim SapGuiAuto, app, conn, sess, tr, guard

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If

' Close any open modal(s), then walk back to the test initial screen
guard = 0
Do While sess.Children.Count > 1 And guard < 5
  sess.FindById("wnd[1]").SendVKey 0
  WScript.Sleep 1200
  guard = guard + 1
Loop

guard = 0
Do While InStr(sess.FindById("wnd[0]").Text, "Test Function Module: Initial Screen") = 0 And guard < 6
  sess.FindById("wnd[0]").SendVKey 3    ' Back
  WScript.Sleep 1500
  guard = guard + 1
Loop

WScript.Echo "SCREEN=" & sess.FindById("wnd[0]").Text
If InStr(sess.FindById("wnd[0]").Text, "Test Function Module: Initial Screen") = 0 Then
  WScript.Echo "ABORT could not reach test screen" : WScript.Quit 11
End If

' ---- SAFETY GATE ----
tr = sess.FindById("wnd[0]/usr/txt[34,11]").Text
WScript.Echo "TESTRUN='" & tr & "'"
If UCase(Trim(tr)) <> "X" Then
  WScript.Echo "ABORT TESTRUN is not X - refusing to execute"
  WScript.Quit 12
End If

WScript.Echo "GOODSMVT_CODE=" & sess.FindById("wnd[0]/usr/lbl[37,10]").Text
WScript.Echo "GOODSMVT_HEADER=" & sess.FindById("wnd[0]/usr/lbl[37,9]").Text
WScript.Echo "EXECUTING TEST RUN..."

sess.FindById("wnd[0]").SendVKey 8
WScript.Sleep 4000

WScript.Echo "AFTER=" & sess.FindById("wnd[0]").Text
If sess.Children.Count > 1 Then WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text
WScript.Echo "SBAR=" & sess.FindById("wnd[0]/sbar").Text
