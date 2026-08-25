Option Explicit
' READ-ONLY. SE16: open table, cap hits, execute, report how many rows came back.
Dim sapGuiAuto, app, conn, sess, elapsed, tbl, i, g
tbl = UCase(WScript.Arguments(0))
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED " & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
CloseModals
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
On Error Resume Next
sess.FindById("wnd[0]/usr/txtMAX_SEL").Text = "20"
If Err.Number <> 0 Then WScript.Echo "  (no MAX_SEL field: " & Err.Description & ")" : Err.Clear
On Error GoTo 0
sess.FindById("wnd[0]").SendVKey 8
Ready 180000
WScript.Echo "TABLE=" & tbl
WScript.Echo "  SBAR=" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "  TITLE=" & sess.FindById("wnd[0]").Text
WScript.Echo "  WINDOWS=" & sess.Children.Count
For i = 1 To sess.Children.Count - 1
  WScript.Echo "  MODAL=" & sess.Children.Item(CLng(i)).Text
Next
On Error Resume Next
Set g = sess.FindById("wnd[0]/usr/cntlRESULT_LIST/shellcont/shell")
If Err.Number = 0 Then
  WScript.Echo "  ALV_ROWS=" & g.RowCount
Else
  Err.Clear
  Set g = sess.FindById("wnd[0]/usr/lbl[1,2]")
  If Err.Number = 0 Then WScript.Echo "  LIST_MODE first label='" & g.Text & "'" Else WScript.Echo "  (no ALV grid, no list label)"
  Err.Clear
End If
On Error GoTo 0
CloseModals
Sub CloseModals()
  Dim guard : guard = 0
  Do While sess.Children.Count > 1 And guard < 6
    sess.FindById("wnd[" & (sess.Children.Count-1) & "]").SendVKey 12 : Ready 8000 : guard = guard + 1
  Loop
End Sub
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 700
End Sub
