Option Explicit
' In an open ABAP editor (QS4/700), positions the cursor on a line and toggles a
' session breakpoint (F9). Reports the status bar so the result is visible.
' USAGE: set-breakpoint.vbs <LINE>
Dim app, conn, s, sess, found, ci, si, ids, i, editor, ln, elapsed

If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|<LINE>" : WScript.Quit 1
ln = CLng(WScript.Arguments(0))

Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For ci = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(ci))
  For si = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(si))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT no QS4/700" : WScript.Quit 9

WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text

ids = Array( _
  "wnd[0]/usr/cntlEDITOR/shellcont/shell", _
  "wnd[0]/usr/subEDITORSUBSCREEN:SAPLEDITOR_START:8430/cntlEDITOR/shellcont/shell", _
  "wnd[0]/usr/subSUBSCREEN:SAPLSEDITOR:0100/cntlEDITOR/shellcont/shell" )
Set editor = Nothing
For i = 0 To UBound(ids)
  On Error Resume Next
  Set editor = sess.FindById(ids(i))
  If Err.Number = 0 And Not editor Is Nothing Then Err.Clear : Exit For
  Set editor = Nothing
  Err.Clear
Next
On Error GoTo 0
If editor Is Nothing Then WScript.Echo "ERR no editor control" : WScript.Quit 5

On Error Resume Next
Err.Clear
editor.SetSelectionIndexes ln, ln
If Err.Number <> 0 Then
  WScript.Echo "WARN SetSelectionIndexes failed: " & Err.Description
  Err.Clear
End If
editor.SetFocus
Err.Clear
On Error GoTo 0
WScript.Sleep 500

sess.FindById("wnd[0]").SendVKey 9      ' F9 = toggle breakpoint
elapsed = 0
Do While sess.Busy And elapsed < 15000
  WScript.Sleep 200 : elapsed = elapsed + 200
Loop
WScript.Sleep 800

WScript.Echo "SBAR=" & sess.FindById("wnd[0]/sbar").Text
If sess.Children.Count > 1 Then WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text
