Option Explicit
Dim rot, sapGui, app, conn, sess, w0, grid, ci, cj, found, k, r, ids, id, val
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
ids = Array("DS4K963155", "DS4K963156", "DS4K963161", "DS4K963162")
For Each id In ids
  If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal before " & id : WScript.Quit 3
  sess.StartTransaction "SE16N"
  WaitReady sess
  If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after tcode " & id : WScript.Quit 4
  Set w0 = sess.FindById("wnd[0]")
  sess.FindById("wnd[0]/usr/ctxtGD-TAB").Text = "E070"
  w0.SendVKey 0
  WaitReady sess
  If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after table " & id : WScript.Quit 5
  sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2,0]").Text = id
  sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
  WaitReady sess
  If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after execute " & id : WScript.Quit 6
  WScript.Echo "QUERY|" & id & "|ROOT=" & sess.FindById("wnd[0]").Text & "|SBAR=" & sess.FindById("wnd[0]/sbar").Text
  On Error Resume Next
  Set grid = sess.FindById("wnd[0]/usr/cntlRESULT_LIST/shellcont/shell")
  If Err.Number <> 0 Then
    WScript.Echo "NOGRID|" & Err.Description
    Err.Clear
  Else
    WScript.Echo "GRID|ROWS=" & grid.RowCount & "|COLS=" & grid.ColumnCount
    For r = 0 To grid.RowCount - 1
      val = grid.GetCellValue(r, "TRKORR") & "|" & grid.GetCellValue(r, "TRFUNCTION") & "|" & grid.GetCellValue(r, "TRSTATUS") & "|" & grid.GetCellValue(r, "TARSYSTEM") & "|" & grid.GetCellValue(r, "KORRDEV") & "|" & grid.GetCellValue(r, "AS4USER") & "|" & grid.GetCellValue(r, "AS4DATE") & "|" & grid.GetCellValue(r, "AS4TIME") & "|" & grid.GetCellValue(r, "STRKORR") & "|" & grid.GetCellValue(r, "AS4TEXT")
      If Len(Replace(val, "|", "")) > 0 Then WScript.Echo "ROW|" & r & "|" & val
    Next
  End If
  On Error GoTo 0
Next
Sub WaitReady(s)
  Do While s.Busy
    WScript.Sleep 200
  Loop
  WScript.Sleep 400
End Sub
