Option Explicit
' Open SE37 Execute > Test Sequences and dump the entry screen.
Dim sapGuiAuto, app, conn, sess, elapsed, k, ch, u

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

If sess.Info.Transaction <> "SE37" Then
  sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
  sess.FindById("wnd[0]").SendVKey 0
  Ready 30000
End If

sess.FindById("wnd[0]/mbar/menu[0]/menu[6]/menu[3]").Select
Ready 60000

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "PROGRAM|" & sess.Info.Program & "|SCREEN|" & sess.Info.ScreenNumber
WScript.Echo "WINDOWS|" & sess.Children.Count
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text
End If
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
