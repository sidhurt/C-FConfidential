Option Explicit
Dim sapGuiAuto, app, sess, elapsed, fm, i, j, conn, s, found, ed, base
fm = UCase(WScript.Arguments(0))
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_200" : WScript.Quit 9

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = fm
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
sess.FindById("wnd[0]").SendVKey 7
Ready 120000

sess.FindById("wnd[0]/usr/tabsFUNC_TAB_STRIP/tabpSOURCE").Select
Ready 120000
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text

base = "wnd[0]/usr/tabsFUNC_TAB_STRIP/tabpSOURCE/ssubSCREEN_HEADER:SAPLEDITOR_START:8430/cntlEDITOR/shellcont/shell"
On Error Resume Next
Set ed = sess.FindById(base)
If Err.Number <> 0 Then
  WScript.Echo "EDITOR_NOT_FOUND|" & Err.Description : WScript.Quit 11
End If
On Error GoTo 0
WScript.Echo "----BEGIN----"
WScript.Echo ed.Text
WScript.Echo "----END----"

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
