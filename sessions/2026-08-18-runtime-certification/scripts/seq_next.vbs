Option Explicit
' Advance an SE37 test sequence to the next function module and dump its test screen.
Dim sapGuiAuto, app, conn, sess, elapsed, k, ch, u

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If

sess.FindById("wnd[0]").SendVKey 3
Ready 90000

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "WINDOWS|" & sess.Children.Count
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text
  WScript.Quit 0
End If
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If Len(Trim(ch.Text)) > 0 Then
    WScript.Echo "  " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & " = '" & ch.Text & "'"
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
  WScript.Sleep 900
End Sub
