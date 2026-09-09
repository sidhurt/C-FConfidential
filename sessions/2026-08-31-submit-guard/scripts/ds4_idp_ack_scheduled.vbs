Option Explicit
' Acknowledge only the exact observed scheduled-job information dialog, once.
Dim app, con, s, sess, i, j, expected, elapsed, n, child
expected = WScript.Arguments(0)
If expected <> "SAP_BC_IDP_WS_SWITCH_BD" And expected <> "SAP_BC_IDP_WS_SWITCH_BDID" Then WScript.Quit 2
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
WScript.Echo "OBSERVE|PROGRAM=" & sess.Info.Program & "|WINDOWS=" & sess.Children.Count & "|TITLE=" & sess.FindById("wnd[0]").Text
If sess.FindById("wnd[0]").Text <> "Program SRT_WS_IDP_CUSTOMIZE" Or sess.Children.Count <> 2 Then WScript.Echo "ABORT|CONTEXT" : WScript.Quit 10
If sess.FindById("wnd[1]").Text <> "Information" Then WScript.Echo "ABORT|DIALOG_TITLE" : WScript.Quit 11
If sess.FindById("wnd[1]/usr/txtMESSTXT1").Text <> "Job " & expected & " scheduled" Then WScript.Echo "ABORT|MESSAGE|" & sess.FindById("wnd[1]/usr/txtMESSTXT1").Text : WScript.Quit 12
WScript.Echo "ACK|Job " & expected & " scheduled"
sess.FindById("wnd[1]").SendVKey 0
elapsed = 0
Do While sess.Busy
  If elapsed >= 30000 Then WScript.Echo "OUTCOME_UNKNOWN|DO_NOT_REINITIALIZE" : WScript.Quit 13
  WScript.Sleep 100 : elapsed = elapsed + 100
Loop
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "STATUS|" & sess.FindById("wnd[0]/sbar").Text
If sess.Children.Count > 1 Then
  WScript.Echo "DIALOG|" & sess.FindById("wnd[1]").Text
  For n = 0 To sess.FindById("wnd[1]/usr").Children.Count - 1
    Set child = sess.FindById("wnd[1]/usr").Children(CLng(n))
    WScript.Echo "CONTROL|" & child.Id & "|" & child.Text
  Next
End If
