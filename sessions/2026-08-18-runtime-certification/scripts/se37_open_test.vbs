Option Explicit
' Open a function module's SE37 single-test screen and dump its parameter layout.
' Navigation only - executes nothing.  Usage: se37_open_test.vbs <FM>
Dim sapGuiAuto, app, conn, sess, fm, elapsed, k, ch, u

If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|<FM>" : WScript.Quit 1
fm = UCase(WScript.Arguments(0))

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = fm
Ready 5000
sess.FindById("wnd[0]/usr/btnBUT3").Press     ' Display
Ready 60000
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_DISPLAY|" & sess.FindById("wnd[1]").Text : WScript.Quit 11
End If
sess.FindById("wnd[0]").SendVKey 8            ' Test
Ready 90000
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_TEST|" & sess.FindById("wnd[1]").Text : WScript.Quit 12
End If

WScript.Echo "FM|" & fm
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "--- parameter rows ---"
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If Len(Trim(ch.Text)) > 0 Then
    WScript.Echo "  [" & ch.Type & "] " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & " = '" & ch.Text & "'"
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
  WScript.Sleep 800
End Sub
