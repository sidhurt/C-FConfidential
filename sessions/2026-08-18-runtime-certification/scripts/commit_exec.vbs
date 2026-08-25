Option Explicit
' Execute BAPI_TRANSACTION_COMMIT with WAIT = X on the current SE37 test screen.
Dim sapGuiAuto, app, conn, sess, elapsed, k, ch, u

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.FindById("wnd[0]/usr/lbl[29,1]").Text <> "BAPI_TRANSACTION_COMMIT" Then
  WScript.Echo "ABORT|WRONG_FM|" & sess.FindById("wnd[0]/usr/lbl[29,1]").Text : WScript.Quit 11
End If

On Error Resume Next
sess.FindById("wnd[0]/usr/txt[34,9]").Text = "X"
If Err.Number <> 0 Then
  WScript.Echo "WAIT_FIELD_ERR|" & Err.Description
  Err.Clear
Else
  WScript.Echo "INPUT|WAIT|txt[34,9]|" & sess.FindById("wnd[0]/usr/txt[34,9]").Text
End If
On Error GoTo 0
Ready 10000

sess.FindById("wnd[0]").SendVKey 8
Ready 180000

WScript.Echo "POST_COMMIT|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "POST_COMMIT|sbar=" & sess.FindById("wnd[0]/sbar").Text
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
  WScript.Sleep 1200
End Sub
