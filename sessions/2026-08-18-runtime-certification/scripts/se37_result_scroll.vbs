Option Explicit
' Read-only: page through the SE37 result screen and dump every visible row.
Dim sapGuiAuto, app, conn, sess, elapsed, k, ch, u, p

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If

For p = 0 To 3
  WScript.Echo "===== VIEW " & p & " | " & sess.FindById("wnd[0]").Text & " ====="
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
  If sess.Children.Count > 1 Then Exit For
  sess.FindById("wnd[0]").SendVKey 82      ' page down
  Ready 30000
Next

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 700
End Sub
