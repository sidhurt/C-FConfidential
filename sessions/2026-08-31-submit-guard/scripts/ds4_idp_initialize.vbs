Option Explicit
' ONE authorized initialization attempt; DS4/200 only. Do not rerun on uncertain outcome.
' Preflight: SM37 all users/statuses found no SAP_BC_IDP_WS_SWITCH_* jobs;
' SRT_IDP_CONF current client empty. User authorized DS4 setup on 2026-08-31.
Dim app, con, candidate, sess, i, j, elapsed, n
If WScript.Arguments.Count <> 1 Then WScript.Quit 2
If WScript.Arguments(0) <> "INITIALIZE_DS4_200_IDP" Then WScript.Quit 2
Set sess = Nothing
Set app = GetObject("SAPGUI").GetScriptingEngine
For i = 0 To app.Children.Count - 1
  Set con = app.Children(CLng(i))
  For j = 0 To con.Children.Count - 1
    Set candidate = con.Children(CLng(j))
    If candidate.Info.SystemName = "DS4" And candidate.Info.Client = "200" Then
      If Not sess Is Nothing Then WScript.Quit 9
      Set sess = candidate
    End If
  Next
Next
If sess Is Nothing Then WScript.Quit 9
If sess.Children.Count > 1 Or sess.Busy Then WScript.Echo "ABORT|NOT_IDLE" : WScript.Quit 10
If sess.Info.Program <> "SRT_WS_IDP_CUSTOMIZE" Then WScript.Echo "ABORT|WRONG_PROGRAM" : WScript.Quit 11
If InStr(sess.FindById("wnd[0]/usr/txtTC_BDJOB").Text, "SAP_BC_IDP_WS_SWITCH_BD") = 0 Then WScript.Quit 11
If InStr(sess.FindById("wnd[0]/usr/txtTC_IDJOB").Text, "SAP_BC_IDP_WS_SWITCH_BDID") = 0 Then WScript.Quit 11
sess.FindById("wnd[0]/usr/chkC_BD").Selected = True
sess.FindById("wnd[0]/usr/chkC_ID").Selected = True
sess.FindById("wnd[0]/usr/txtP_BD_D").Text = "0"
sess.FindById("wnd[0]/usr/txtP_BD_H").Text = "6"
sess.FindById("wnd[0]/usr/txtP_ID_D").Text = "0"
sess.FindById("wnd[0]/usr/txtP_ID_H").Text = "12"
If CInt(sess.FindById("wnd[0]/usr/txtP_BD_H").Text) <> 6 Then WScript.Quit 12
If CInt(sess.FindById("wnd[0]/usr/txtP_ID_H").Text) <> 12 Then WScript.Quit 12
WScript.Echo "EXECUTE_ONCE|DS4|200|WSIDPADMIN|BD=6h|BDID=12h"
sess.FindById("wnd[0]").SendVKey 8
elapsed = 0
Do While sess.Busy
  If elapsed >= 30000 Then WScript.Echo "OUTCOME_UNKNOWN|BUSY|DO_NOT_RERUN" : WScript.Quit 13
  WScript.Sleep 100 : elapsed = elapsed + 100
Loop
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "STATUS|" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "STATUS_TYPE|" & sess.FindById("wnd[0]/sbar").MessageType
For n = 1 To sess.Children.Count - 1
  WScript.Echo "DIALOG|" & sess.FindById("wnd[" & n & "]").Text
  Walk sess.FindById("wnd[" & n & "]/usr")
Next
Sub Walk(node)
  Dim k, count
  WScript.Echo "CONTROL|" & node.Id & "|" & node.Type & "|" & node.Text
  count = 0
  On Error Resume Next
  count = node.Children.Count
  On Error GoTo 0
  For k = 0 To count - 1
    Walk node.Children.Item(CLng(k))
  Next
End Sub
