Option Explicit
' Generic SE37 test-screen helper.
'   se37_set_and_drill.vbs SET <fieldId> <value> [<fieldId> <value> ...]
'   se37_set_and_drill.vbs DRILL <labelRow>
'   se37_set_and_drill.vbs FILL <col,row> <value> [<col,row> <value> ...]
'   se37_set_and_drill.vbs BACK
'   se37_set_and_drill.vbs EXEC
Dim sapGuiAuto, app, conn, sess, elapsed, mode, i, k, ch, u

mode = UCase(WScript.Arguments(0))

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

Select Case mode

Case "SET"
  For i = 1 To WScript.Arguments.Count - 1 Step 2
    On Error Resume Next
    sess.FindById("wnd[0]/usr/" & WScript.Arguments(i)).Text = WScript.Arguments(i+1)
    If Err.Number <> 0 Then
      WScript.Echo "ERR|" & WScript.Arguments(i) & "|" & Err.Description
      Err.Clear
    Else
      WScript.Echo "SET|" & WScript.Arguments(i) & "=" & sess.FindById("wnd[0]/usr/" & WScript.Arguments(i)).Text
    End If
    On Error GoTo 0
  Next

Case "FILL"
  For i = 1 To WScript.Arguments.Count - 1 Step 2
    On Error Resume Next
    sess.FindById("wnd[0]/usr/txt[" & WScript.Arguments(i) & "]").Text = WScript.Arguments(i+1)
    If Err.Number <> 0 Then
      WScript.Echo "ERR|txt[" & WScript.Arguments(i) & "]|" & Err.Description
      Err.Clear
    Else
      WScript.Echo "FILL|txt[" & WScript.Arguments(i) & "]=" & sess.FindById("wnd[0]/usr/txt[" & WScript.Arguments(i) & "]").Text
    End If
    On Error GoTo 0
  Next

Case "DRILL"
  sess.FindById("wnd[0]/usr/lbl[2," & WScript.Arguments(1) & "]").SetFocus
  sess.FindById("wnd[0]/usr/lbl[2," & WScript.Arguments(1) & "]").CaretPosition = 3
  sess.FindById("wnd[0]").SendVKey 2
  Ready 60000
  WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
  Dump

Case "BACK"
  sess.FindById("wnd[0]").SendVKey 3
  Ready 60000
  WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text

Case "EXEC"
  sess.FindById("wnd[0]").SendVKey 8
  Ready 300000
  If sess.Children.Count > 1 Then
    WScript.Echo "MODAL_AFTER_EXEC|" & sess.FindById("wnd[1]").Text : WScript.Quit 13
  End If
  WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
  WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text
  Dump

Case "DUMP"
  WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
  Dump

End Select

Sub Dump()
  Dim u2, k2, c2, sid
  Set u2 = sess.FindById("wnd[0]/usr")
  For k2 = 0 To u2.Children.Count - 1
    Set c2 = u2.Children.Item(CLng(k2))
    On Error Resume Next
    sid = c2.Id
    sid = Mid(sid, InStr(sid, "/usr/") + 5)
    If Len(Trim(c2.Text)) > 0 Then
      WScript.Echo "  [" & c2.Type & "] " & sid & " = '" & c2.Text & "'"
    ElseIf c2.Type = "GuiTextField" Or c2.Type = "GuiCTextField" Then
      WScript.Echo "  [" & c2.Type & "] " & sid & " = ''"
    End If
    Err.Clear
    On Error GoTo 0
  Next
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
