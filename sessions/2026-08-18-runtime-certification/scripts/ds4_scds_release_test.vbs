Option Explicit
' Set I_OPT_WITH_DIALOG to blank on the already-open SD_SCDS_RELEASE test screen
' and execute. I_REFOBJ_TAB is left empty (0 entries) so there is nothing to act on.
Dim sapGuiAuto, app, sess, elapsed, i, j, conn, s, found, k
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

WScript.Echo "BEFORE|I_OPT_WITH_DIALOG='" & sess.FindById("wnd[0]/usr/txt[34,7]").Text & "'"
sess.FindById("wnd[0]/usr/txt[34,7]").Text = ""
WScript.Echo "AFTER |I_OPT_WITH_DIALOG='" & sess.FindById("wnd[0]/usr/txt[34,7]").Text & "'"

sess.FindById("wnd[0]").SendVKey 8
Ready 300000

WScript.Echo "WINDOWS|" & sess.Children.Count
For k = 1 To sess.Children.Count - 1
  WScript.Echo "MODAL" & k & "|" & sess.Children.Item(CLng(k)).Text
Next
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "TCODE|" & sess.Info.Transaction
WScript.Echo "PROGRAM|" & sess.Info.Program
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 1500
End Sub
