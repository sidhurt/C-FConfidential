Option Explicit
' Open Gateway client in DS4/200 for safe header probe preparation. No request executed.
Dim app, con, s, sess, i, j, elapsed
Set sess = Nothing
Set app = GetObject("SAPGUI").GetScriptingEngine
For i = 0 To app.Children.Count - 1
  Set con = app.Children(CLng(i))
  For j = 0 To con.Children.Count - 1
    Set s = con.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then
      If Not sess Is Nothing Then WScript.Quit 9
      Set sess = s
    End If
  Next
Next
If sess Is Nothing Then WScript.Quit 9
If sess.Children.Count > 1 Or sess.Busy Then WScript.Echo "ABORT|SESSION_NOT_IDLE" : WScript.Quit 10
WScript.Echo "SESSION|" & sess.Info.SystemName & "|" & sess.Info.Client
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n/IWFND/GW_CLIENT"
sess.FindById("wnd[0]").SendVKey 0
elapsed = 0
Do While sess.Busy
  If elapsed >= 30000 Then WScript.Quit 10
  WScript.Sleep 100 : elapsed = elapsed + 100
Loop
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "STATUS|" & sess.FindById("wnd[0]/sbar").Text
If sess.Children.Count > 1 Then
  WScript.Echo "DIALOG|" & sess.FindById("wnd[1]").Text
  Walk sess.FindById("wnd[1]/usr")
Else
  Walk sess.FindById("wnd[0]/usr")
  Walk sess.FindById("wnd[0]/tbar[1]")
End If
Sub Walk(node)
  Dim n, count, tx, st, k
  On Error Resume Next
  tx = node.Text
  WScript.Echo "CONTROL|" & node.Id & "|" & node.Type & "|" & tx
  st = "" : st = node.SubType : Err.Clear
  If st = "GridView" Then
    For k = 0 To node.ToolbarButtonCount - 1
      WScript.Echo "TOOLBAR|" & node.Id & "|" & k & "|" & node.GetToolbarButtonId(CLng(k)) & "|" & node.GetToolbarButtonTooltip(CLng(k))
    Next
  End If
  Err.Clear : count = node.Children.Count
  If Err.Number <> 0 Then On Error GoTo 0 : Exit Sub
  On Error GoTo 0
  For n = 0 To count - 1
    Walk node.Children.Item(CLng(n))
  Next
End Sub
