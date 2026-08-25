Option Explicit
Dim rot, sapGui, app, conn, sess, w0, tbl, ci, cj, found, i
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
If Not found Then WScript.Echo "STOP|DS4" : WScript.Quit 2
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal before" : WScript.Quit 3
On Error Resume Next
sess.StartTransaction "SE16N"
WScript.Echo "STARTERR|" & Err.Number & "|" & Err.Description
Err.Clear
Do While sess.Busy: WScript.Sleep 200: Loop
WScript.Sleep 500
WScript.Echo "STARTED|" & sess.Info.Transaction & "|" & sess.Children.Count
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after start" : WScript.Quit 4
Set w0 = sess.FindById("wnd[0]")
WScript.Echo "ROOT|" & w0.Text
sess.FindById("wnd[0]/usr/ctxtGD-TAB").Text = "E070"
WScript.Echo "SETTABERR|" & Err.Number & "|" & Err.Description
Err.Clear
w0.SendVKey 0
WScript.Echo "ENTERERR|" & Err.Number & "|" & Err.Description
Err.Clear
Do While sess.Busy: WScript.Sleep 200: Loop
WScript.Sleep 500
WScript.Echo "TABLE|" & sess.Info.Transaction & "|" & sess.Children.Count & "|SBAR=" & sess.FindById("wnd[0]/sbar").Text
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after enter" : WScript.Quit 5
For i = 0 To 8
  WScript.Echo "F|" & i & "|" & sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/txtGS_SELFIELDS-FIELDNAME[6," & i & "]").Text
Next
sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2,3]").Text = "QS4"
WScript.Echo "SETQS4ERR|" & Err.Number & "|" & Err.Description
Err.Clear
sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2,6]").Text = "20.08.2026"
WScript.Echo "SETLOWERR|" & Err.Number & "|" & Err.Description
Err.Clear
sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-HIGH[3,6]").Text = "22.08.2026"
WScript.Echo "SETHIGHERR|" & Err.Number & "|" & Err.Description
Err.Clear
WScript.Echo "BEFOREEXEC|" & sess.FindById("wnd[0]/sbar").Text
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
WScript.Echo "EXECERR|" & Err.Number & "|" & Err.Description
Err.Clear
Do While sess.Busy: WScript.Sleep 200: Loop
WScript.Sleep 800
WScript.Echo "AFTEREXEC|" & sess.Info.Transaction & "|WINDOWS=" & sess.Children.Count & "|ROOT=" & sess.FindById("wnd[0]").Text & "|SBAR=" & sess.FindById("wnd[0]/sbar").Text
Dim usr, child, grid
Set usr = sess.FindById("wnd[0]/usr")
WScript.Echo "USRCOUNT=" & usr.Children.Count
For i = 0 To usr.Children.Count - 1
  Set child = usr.Children.Item(CLng(i))
  WScript.Echo "CTRL|" & child.Id & "|" & child.Type & "|" & child.Name
Next
Set grid = sess.FindById("wnd[0]/usr/cntlRESULT_LIST/shellcont/shell")
WScript.Echo "GRID|" & grid.Id & "|ROWS=" & grid.RowCount & "|COLS=" & grid.ColumnCount
WScript.Echo "COLORDER=" & grid.ColumnOrder
For i = 0 To grid.ColumnCount - 1
  WScript.Echo "COL|" & i & "|" & grid.ColumnOrder(i)
Next
Dim r, v
For r = 0 To grid.RowCount - 1
  v = grid.GetCellValue(r, "TRKORR") & "|" & grid.GetCellValue(r, "TRFUNCTION") & "|" & grid.GetCellValue(r, "TRSTATUS") & "|" & grid.GetCellValue(r, "TARSYSTEM") & "|" & grid.GetCellValue(r, "KORRDEV") & "|" & grid.GetCellValue(r, "AS4USER") & "|" & grid.GetCellValue(r, "AS4DATE") & "|" & grid.GetCellValue(r, "AS4TIME") & "|" & grid.GetCellValue(r, "STRKORR") & "|" & grid.GetCellValue(r, "AS4TEXT")
  WScript.Echo "ROW|" & r & "|" & v
Next
On Error GoTo 0
