Option Explicit
' STEP 7 (read-only): from the SE37 result screen, dump the remaining result rows,
' then drill into the RETURN table result and dump every row and column.
Dim sapGuiAuto, app, conn, sess, elapsed, u, k, ch

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "ABORT|WRONG_SYSTEM_OR_CLIENT|" & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text
  WScript.Quit 10
End If
If sess.FindById("wnd[0]").Text <> "Test Function Module: Result Screen" Then
  WScript.Echo "ABORT|UNEXPECTED_SCREEN|" & sess.FindById("wnd[0]").Text
  WScript.Quit 11
End If

WScript.Echo "=== FULL RESULT SCREEN (all non-empty labels) ==="
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

' --- drill into the RETURN result (the 'Result:' line under RETURN) ---
WScript.Echo "=== DRILL INTO RETURN RESULT ==="
sess.FindById("wnd[0]/usr/lbl[37,38]").SetFocus
sess.FindById("wnd[0]/usr/lbl[37,38]").CaretPosition = 3
sess.FindById("wnd[0]").SendVKey 2
Ready 90000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_PRESENT|" & sess.FindById("wnd[1]").Text & "  <-- left open, not dismissed"
  WScript.Quit 13
End If

WScript.Echo "AFTER_DRILL|title=" & sess.FindById("wnd[0]").Text & _
  "|program=" & sess.Info.Program & "|screen=" & sess.Info.ScreenNumber
WScript.Echo "AFTER_DRILL|SBAR=" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "--- TABLE CONTENT ---"
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
  WScript.Sleep 900
End Sub
