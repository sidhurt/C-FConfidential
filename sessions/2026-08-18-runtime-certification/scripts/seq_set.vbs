Option Explicit
' Populate the SE37 "Select Function Module" test-sequence dialog and start it.
' Usage: seq_set.vbs <FM1> <FM2> ...
Dim sapGuiAuto, app, conn, sess, elapsed, i, base

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count < 2 Then WScript.Echo "ABORT|NO_DIALOG" : WScript.Quit 10
If sess.FindById("wnd[1]").Text <> "Select Function Module" Then
  WScript.Echo "ABORT|UNEXPECTED_MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 11
End If

base = "wnd[1]/usr/tblSAPLSEUJCONTROL_SEQFUNC/ctxtRS38L-NAME[0,"
For i = 0 To WScript.Arguments.Count - 1
  sess.FindById(base & i & "]").Text = UCase(WScript.Arguments(i))
  WScript.Echo "SEQ[" & i & "]=" & UCase(WScript.Arguments(i))
Next
Ready 15000

sess.FindById("wnd[1]/tbar[0]/btn[0]").Press     ' Execute sequence
Ready 90000

WScript.Echo "AFTER|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "AFTER|windows=" & sess.Children.Count
If sess.Children.Count > 1 Then WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
