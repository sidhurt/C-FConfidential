Option Explicit
' STEP 10 (read-only): widen the logical working pane (display only, no data change),
' re-open the RETURN table result and dump all columns.
Dim sapGuiAuto, app, conn, sess, elapsed, u, k, ch, origW, origH

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

On Error Resume Next
origW = sess.FindById("wnd[0]").Width
origH = sess.FindById("wnd[0]").Height
WScript.Echo "PANE_BEFORE|width=" & origW & "|height=" & origH
sess.FindById("wnd[0]").ResizeWorkingPane 250, 35, False
If Err.Number <> 0 Then
  WScript.Echo "RESIZE_FAILED|" & Err.Description
  Err.Clear
End If
On Error GoTo 0
Ready 30000
WScript.Echo "PANE_AFTER|width=" & sess.FindById("wnd[0]").Width & "|height=" & sess.FindById("wnd[0]").Height

' re-open RETURN result
sess.FindById("wnd[0]/usr/lbl[37,38]").SetFocus
sess.FindById("wnd[0]/usr/lbl[37,38]").CaretPosition = 3
sess.FindById("wnd[0]").SendVKey 2
Ready 90000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_PRESENT|" & sess.FindById("wnd[1]").Text & "  <-- left open, not dismissed"
  WScript.Quit 13
End If

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "--- RETURN, WIDE VIEW ---"
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
