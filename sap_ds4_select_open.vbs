Option Explicit
Dim rot, sapGui, app, conn, sess, w0, tbl, i, fld, low, high
Set rot = CreateObject("SapROTWr.SapROTWrapper")
Set sapGui = rot.GetROTEntry("SAPGUI")
Set app = sapGui.GetScriptingEngine
Dim ci, cj, found
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
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal before action" : WScript.Quit 3
Set w0 = sess.FindById("wnd[0]")
If sess.Info.Transaction <> "SE16N" Then sess.StartTransaction "SE16N" : WaitReady sess
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after transaction" : WScript.Quit 4
On Error Resume Next
sess.FindById("wnd[0]/usr/ctxtGD-TAB").Text = "E070"
If Err.Number <> 0 Then WScript.Echo "STOP|table field|" & Err.Description : WScript.Quit 5
Err.Clear
w0.SendVKey 0
If Err.Number <> 0 Then WScript.Echo "STOP|enter|" & Err.Description : WScript.Quit 6
On Error GoTo 0
WaitReady sess
WScript.Echo "CONFIRM|" & sess.Info.SystemName & "|" & sess.Info.Client & "|" & sess.Info.Transaction
WScript.Echo "WINDOWS=" & sess.Children.Count
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal after Enter" : WScript.Quit 7
Set tbl = sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC")
For i = 0 To 8
  Set fld = sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/txtGS_SELFIELDS-FIELDNAME[6," & i & "]")
  Set low = sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-LOW[2," & i & "]")
  Set high = sess.FindById("wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/ctxtGS_SELFIELDS-HIGH[3," & i & "]")
  WScript.Echo "FIELD|" & i & "|" & fld.Text & "|LOW=" & low.Text & "|HIGH=" & high.Text
Next
Sub WaitReady(s)
  Do While s.Busy
    WScript.Sleep 200
  Loop
  WScript.Sleep 300
End Sub
