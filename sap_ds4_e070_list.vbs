Option Explicit
Dim rot, sapGui, app, conn, sess, w0, ci, cj, found, i, c, root, grid
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
If Not found Then WScript.Echo "STOP|DS4/200" : WScript.Quit 2
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal before" : WScript.Quit 3
If sess.Info.Transaction <> "SE16N" Then sess.StartTransaction "SE16N" : WaitReady sess
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after tcode" : WScript.Quit 4
Set w0 = sess.FindById("wnd[0]")
On Error Resume Next
sess.FindById("wnd[0]/usr/ctxtGD-TAB").Text = "E070"
w0.SendVKey 0
If Err.Number <> 0 Then WScript.Echo "STOP|open E070|" & Err.Description : WScript.Quit 5
On Error GoTo 0
WaitReady sess
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after table" : WScript.Quit 6
sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2,3]").Text = "QS4"
sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2,6]").Text = "20260820"
sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-HIGH[3,6]").Text = "20260822"
w0.SendVKey 8
WaitReady sess
WScript.Echo "AFTER|" & sess.Info.Transaction & "|WINDOWS=" & sess.Children.Count & "|ROOT=" & w0.Text
WScript.Echo "SCREEN=" & sess.Info.ScreenNumber & "|SBAR=" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "FILTERS|TARSYSTEM=" & sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2,3]").Text & "|DATELOW=" & sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2,6]").Text & "|DATEHIGH=" & sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-HIGH[3,6]").Text
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after execute" : WScript.Quit 7
Set root = sess.FindById("wnd[0]/usr")
WScript.Echo "USRCHILDREN=" & root.Children.Count
For i = 0 To root.Children.Count - 1
  On Error Resume Next
  Set c = root.Children.Item(CLng(i))
  WScript.Echo "CTRL|" & c.Id & "|" & c.Type & "|" & c.Name & "|" & c.Text
  If Err.Number <> 0 Then Err.Clear
  On Error GoTo 0
Next
On Error Resume Next
Set grid = sess.FindById("wnd[0]/usr/cntlRESULT_LIST/shellcont/shell")
If Err.Number = 0 Then
  WScript.Echo "GRID|" & grid.Id & "|ROWS=" & grid.RowCount & "|COLS=" & grid.ColumnCount
  WScript.Echo "COLORDER|" & grid.ColumnOrder
  For i = 0 To grid.ColumnCount - 1
    WScript.Echo "COL|" & i & "|" & grid.ColumnOrder(i)
  Next
Else
  WScript.Echo "NOGRID|" & Err.Description
End If
On Error GoTo 0
Sub WaitReady(s)
  Do While s.Busy
    WScript.Sleep 200
  Loop
  WScript.Sleep 300
End Sub
