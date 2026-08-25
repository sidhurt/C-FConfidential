Option Explicit
' Drill into a structure row on the SE37 single-test screen and dump its fields.
' Usage: se37_drill_struct.vbs <labelRow>     e.g. 9 for HEADERDATA
Dim sapGuiAuto, app, conn, sess, elapsed, row, k, ch, u

If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|<labelRow>" : WScript.Quit 1
row = WScript.Arguments(0)

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

sess.FindById("wnd[0]/usr/lbl[2," & row & "]").SetFocus
sess.FindById("wnd[0]/usr/lbl[2," & row & "]").CaretPosition = 3
sess.FindById("wnd[0]").SendVKey 2
Ready 60000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 12
End If

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  WScript.Echo "  [" & ch.Type & "] " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & " = '" & ch.Text & "'"
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
