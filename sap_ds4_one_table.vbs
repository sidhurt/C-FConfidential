Option Explicit
Dim tableName, key, rot, sapGui, app, conn, sess, w0, grid, ci, cj, found, r, c, colName, line
If WScript.Arguments.Count < 2 Then WScript.Echo "STOP|need table key" : WScript.Quit 2
tableName = WScript.Arguments(0)
key = WScript.Arguments(1)
Set rot = CreateObject("SapROTWr.SapROTWrapper")
Set sapGui = rot.GetROTEntry("SAPGUI")
Set app = sapGui.GetScriptingEngine
found = False
For ci = 0 To app.Children.Count - 1
  Set conn = app.Children.Item(CLng(ci))
  For cj = 0 To conn.Children.Count - 1
    Set sess = conn.Children.Item(CLng(cj))
    If sess.Info.SystemName = "DS4" And sess.Info.Client = "200" Then found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "STOP|DS4/200" : WScript.Quit 3
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal before" : WScript.Quit 4
sess.StartTransaction "SE16N"
WaitReady sess
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after tcode" : WScript.Quit 5
Set w0 = sess.FindById("wnd[0]")
sess.FindById("wnd[0]/usr/ctxtGD-TAB").Text = tableName
w0.SendVKey 0
WaitReady sess
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after table" : WScript.Quit 6
sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2,0]").Text = key
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
WaitReady sess
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after execute" : WScript.Quit 7
WScript.Echo "QUERY|" & tableName & "|" & key & "|ROOT=" & sess.FindById("wnd[0]").Text & "|SBAR=" & sess.FindById("wnd[0]/sbar").Text
On Error Resume Next
Set grid = sess.FindById("wnd[0]/usr/cntlRESULT_LIST/shellcont/shell")
If Err.Number <> 0 Then
  WScript.Echo "NOGRID|" & Err.Description
  Err.Clear
Else
  WScript.Echo "GRID|ROWS=" & grid.RowCount & "|COLS=" & grid.ColumnCount
  line = "COLS"
  For c = 0 To grid.ColumnCount - 1
    line = line & "|" & grid.ColumnOrder(c)
  Next
  WScript.Echo line
  For r = 0 To grid.RowCount - 1
    line = "ROW|" & r
    For c = 0 To grid.ColumnCount - 1
      colName = grid.ColumnOrder(c)
      line = line & "|" & colName & "=" & grid.GetCellValue(r, colName)
    Next
    WScript.Echo line
  Next
End If
On Error GoTo 0
Sub WaitReady(s)
  Do While s.Busy
    WScript.Sleep 200
  Loop
  WScript.Sleep 400
End Sub
