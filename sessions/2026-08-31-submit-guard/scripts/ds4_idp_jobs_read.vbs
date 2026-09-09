Option Explicit
' Read-only SM37 preflight for standard idempotency jobs.
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
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSM37"
sess.FindById("wnd[0]").SendVKey 0
elapsed = 0
Do While sess.Busy
  If elapsed >= 30000 Then WScript.Quit 10
  WScript.Sleep 100 : elapsed = elapsed + 100
Loop
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL" : WScript.Quit 10
sess.FindById("wnd[0]/usr/txtBTCH2170-JOBNAME").Text = "SAP_BC_IDP_WS_SWITCH_*"
sess.FindById("wnd[0]/usr/txtBTCH2170-USERNAME").Text = "*"
sess.FindById("wnd[0]/usr/ctxtBTCH2170-FROM_DATE").Text = "01.01.2000"
sess.FindById("wnd[0]/usr/ctxtBTCH2170-TO_DATE").Text = "31.12.9999"
For Each i In Array("PRELIM", "SCHEDUL", "READY", "RUNNING", "FINISHED", "ABORTED")
  sess.FindById("wnd[0]/usr/chkBTCH2170-" & i).Selected = True
Next
WScript.Echo "QUERY|SAP_BC_IDP_WS_SWITCH_*|ALL_USERS|ALL_STATUSES|20000101-99991231"
sess.FindById("wnd[0]").SendVKey 8
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
End If
Sub Walk(node)
  Dim n, count, tx, cols, c, r, line, st
  On Error Resume Next
  tx = node.Text
  WScript.Echo "CONTROL|" & node.Id & "|" & node.Type & "|" & tx
  st = "" : st = node.SubType : Err.Clear
  If st = "GridView" Then
    WScript.Echo "GRID_ROWS|" & node.RowCount
    Set cols = node.ColumnOrder
    For r = 0 To node.RowCount - 1
      If r >= 100 Then Exit For
      line = "ROW|" & r
      For c = 0 To cols.Count - 1
        line = line & "|" & cols(c) & "=" & node.GetCellValue(CLng(r), CStr(cols(c)))
      Next
      WScript.Echo line
    Next
  End If
  Err.Clear : count = node.Children.Count
  If Err.Number <> 0 Then On Error GoTo 0 : Exit Sub
  On Error GoTo 0
  For n = 0 To count - 1
    Walk node.Children.Item(CLng(n))
  Next
End Sub
