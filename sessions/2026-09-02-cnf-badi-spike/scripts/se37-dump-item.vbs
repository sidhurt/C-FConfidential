Option Explicit
' Opens GOODSMVT_ITEM from the SE37 result screen and dumps row 1 field values.
' Read-only inspection of what the harness actually sent.
Dim app, conn, sess, s, ci, si, found, r, lab, val, vpos

Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For ci = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(ci))
  For si = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(si))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT no QS4/700" : WScript.Quit 9

WScript.Echo "START=" & sess.FindById("wnd[0]").Text

' click the GOODSMVT_ITEM row on the result screen
On Error Resume Next
Err.Clear
sess.FindById("wnd[0]/usr/lbl[2,27]").SetFocus
If Err.Number <> 0 Then WScript.Echo "ERR focus lbl[2,27]: " & Err.Description : Err.Clear
On Error GoTo 0
sess.FindById("wnd[0]").SendVKey 2 : WScript.Sleep 2500
WScript.Echo "TABLE=" & sess.FindById("wnd[0]").Text

' switch to single-entry view of row 1
On Error Resume Next
Err.Clear
sess.FindById("wnd[0]/tbar[1]/btn[19]").Press
If Err.Number <> 0 Then WScript.Echo "ERR btn19: " & Err.Description : Err.Clear
On Error GoTo 0
WScript.Sleep 2500

If sess.Children.Count < 2 Then
  WScript.Echo "NO_MODAL - dumping wnd[0] labels instead"
  For r = 2 To 24
    On Error Resume Next
    Err.Clear
    lab = sess.FindById("wnd[0]/usr/lbl[2," & r & "]").Text
    If Err.Number = 0 And Len(Trim(lab)) > 0 Then WScript.Echo "  " & r & ": " & lab
    Err.Clear
    On Error GoTo 0
  Next
  WScript.Quit 0
End If

WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text
For Each vpos In Array(0, 40, 68, 104)
  On Error Resume Next
  Err.Clear
  sess.FindById("wnd[1]/usr").VerticalScrollbar.Position = CLng(vpos)
  Err.Clear
  On Error GoTo 0
  WScript.Sleep 900
  WScript.Echo "-- scroll " & vpos
  For r = 2 To 22
    On Error Resume Next
    Err.Clear
    lab = sess.FindById("wnd[1]/usr/lbl[12," & r & "]").Text
    If Err.Number = 0 And Len(Trim(lab)) > 0 Then
      Err.Clear
      val = sess.FindById("wnd[1]/usr/txt[43," & r & "]").Text
      If Err.Number = 0 And Len(Trim(val)) > 0 Then
        WScript.Echo "   " & lab & " = '" & Trim(val) & "'"
      End If
    End If
    Err.Clear
    On Error GoTo 0
  Next
Next
