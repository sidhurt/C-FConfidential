Option Explicit
' STEP 11 (read-only): on the RETURN structure-editor list, identify the application
' toolbar buttons and press "Entry" to open the single-entry view with all fields.
Dim sapGuiAuto, app, conn, sess, elapsed, i, b, u, k, ch, entryId

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

WScript.Echo "--- application toolbar ---"
entryId = ""
Set u = sess.FindById("wnd[0]/tbar[1]")
For k = 0 To u.Children.Count - 1
  Set b = u.Children.Item(CLng(k))
  On Error Resume Next
  WScript.Echo "  " & Replace(b.Id, "/app/con[0]/ses[0]/wnd[0]/", "") & " text='" & b.Text & "' tip='" & b.Tooltip & "'"
  If InStr(b.Text, "Entry") > 0 Then entryId = b.Id
  Err.Clear
  On Error GoTo 0
Next

If entryId = "" Then
  WScript.Echo "NO_ENTRY_BUTTON|stopping without further navigation"
  WScript.Quit 0
End If

' put the cursor on the ME013 row first so Entry opens that message
On Error Resume Next
sess.FindById("wnd[0]/usr/lbl[3,8]").SetFocus
sess.FindById("wnd[0]/usr/lbl[3,8]").CaretPosition = 2
Err.Clear
On Error GoTo 0

sess.FindById(entryId).Press
Ready 60000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_PRESENT|" & sess.FindById("wnd[1]").Text & "  <-- left open, not dismissed"
  WScript.Quit 13
End If

WScript.Echo "ENTRY_VIEW|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "--- all fields ---"
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
