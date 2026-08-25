Option Explicit
' STEP 9 (read-only): drill into each RETURN row in turn and dump every field,
' returning to the list between rows. Stops if any modal appears.
Dim sapGuiAuto, app, conn, sess, elapsed, rows_, r, rowLine, u, k, ch

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
If InStr(sess.FindById("wnd[0]").Text, "RETURN") = 0 Then
  WScript.Echo "ABORT|UNEXPECTED_SCREEN|" & sess.FindById("wnd[0]").Text
  WScript.Quit 11
End If

rows_ = Array(6, 7, 8, 9)
For r = 0 To UBound(rows_)
  rowLine = rows_(r)
  WScript.Echo "========== RETURN ROW AT SCREEN LINE " & rowLine & " =========="

  On Error Resume Next
  sess.FindById("wnd[0]/usr/lbl[3," & rowLine & "]").SetFocus
  If Err.Number <> 0 Then
    WScript.Echo "  SKIP|no label at lbl[3," & rowLine & "]|" & Err.Description
    Err.Clear
    On Error GoTo 0
  Else
    sess.FindById("wnd[0]/usr/lbl[3," & rowLine & "]").CaretPosition = 2
    On Error GoTo 0
    sess.FindById("wnd[0]").SendVKey 2
    Ready 60000

    If sess.Children.Count > 1 Then
      WScript.Echo "  MODAL_PRESENT|" & sess.FindById("wnd[1]").Text & "  <-- left open, not dismissed"
      WScript.Quit 13
    End If

    WScript.Echo "  DETAIL_TITLE|" & sess.FindById("wnd[0]").Text
    Set u = sess.FindById("wnd[0]/usr")
    For k = 0 To u.Children.Count - 1
      Set ch = u.Children.Item(CLng(k))
      On Error Resume Next
      If Len(Trim(ch.Text)) > 0 Then
        WScript.Echo "    " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & " = '" & ch.Text & "'"
      End If
      Err.Clear
      On Error GoTo 0
    Next

    ' back to the RETURN list
    sess.FindById("wnd[0]").SendVKey 3
    Ready 60000
    If sess.Children.Count > 1 Then
      WScript.Echo "  MODAL_AFTER_BACK|" & sess.FindById("wnd[1]").Text & "  <-- left open"
      WScript.Quit 14
    End If
  End If
Next

WScript.Echo "FINAL|title=" & sess.FindById("wnd[0]").Text

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
