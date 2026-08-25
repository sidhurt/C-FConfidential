Option Explicit
' STEP 8 (read-only): horizontally scroll the RETURN structure-editor list and dump
' every column at each offset, so MESSAGE_V1..V4 / PARAMETER / ROW / FIELD are captured.
Dim sapGuiAuto, app, conn, sess, elapsed, u, k, ch, pos, positions, i, maxPos

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

On Error Resume Next
maxPos = sess.FindById("wnd[0]").HorizontalScrollbar.Maximum
If Err.Number <> 0 Then
  WScript.Echo "NO_HSCROLL|" & Err.Description
  maxPos = 0
  Err.Clear
End If
On Error GoTo 0
WScript.Echo "HSCROLL_MAX|" & maxPos

positions = Array(0, 60, 120, 180, 240)
For i = 0 To UBound(positions)
  pos = positions(i)
  If pos > maxPos Then Exit For
  On Error Resume Next
  sess.FindById("wnd[0]").HorizontalScrollbar.Position = pos
  If Err.Number <> 0 Then Err.Clear : Exit For
  On Error GoTo 0
  Ready 30000
  WScript.Echo "===== HSCROLL POSITION " & pos & " ====="
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
Next

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
