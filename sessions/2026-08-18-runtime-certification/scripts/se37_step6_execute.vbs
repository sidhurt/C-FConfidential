Option Explicit
' STEP 6: execute BAPI_PO_CREATE1 ONCE with F8 from the SE37 single-test screen.
' TESTRUN = X. No commit is issued. Stops and describes any modal instead of closing it.
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
  WScript.Echo "ABORT|MODAL_ALREADY_OPEN|" & sess.FindById("wnd[1]").Text
  WScript.Quit 10
End If
If sess.FindById("wnd[0]").Text <> "Test Function Module: Initial Screen" Then
  WScript.Echo "ABORT|UNEXPECTED_SCREEN|" & sess.FindById("wnd[0]").Text
  WScript.Quit 11
End If
If sess.FindById("wnd[0]/usr/txt[34,12]").Text <> "X" Then
  WScript.Echo "ABORT|TESTRUN_NOT_SET|'" & sess.FindById("wnd[0]/usr/txt[34,12]").Text & "'"
  WScript.Quit 12
End If

WScript.Echo "PRE_EXEC|TESTRUN=X|POHEADER-DOC_TYPE=ZP06|POHEADERX-DOC_TYPE=X"
sess.FindById("wnd[0]").SendVKey 8
Ready 300000

WScript.Echo "POST_EXEC|title=" & sess.FindById("wnd[0]").Text & _
  "|program=" & sess.Info.Program & "|screen=" & sess.Info.ScreenNumber
WScript.Echo "POST_EXEC|SBAR=" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "POST_EXEC|WINDOWS=" & sess.Children.Count
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_PRESENT|" & sess.FindById("wnd[1]").Text & "  <-- left open, not dismissed"
  WScript.Quit 13
End If

WScript.Echo "--- RESULT SCREEN ---"
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If ch.Type = "GuiLabel" Or ch.Type = "GuiTextField" Or ch.Type = "GuiCTextField" Then
    If Len(Trim(ch.Text)) > 0 Then
      WScript.Echo "  [" & ch.Type & "] " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & " = '" & ch.Text & "'"
    End If
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
