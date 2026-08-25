Option Explicit
Dim app, sess, i, j, conn, s, found, elapsed, tc, u, k, ch
tc = WScript.Arguments(0)
Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "300" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_300" : WScript.Quit 9
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n" & tc
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "TCODE|" & sess.Info.Transaction
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "MODALS|" & (sess.Children.Count - 1)
For k = 1 To sess.Children.Count - 1
  WScript.Echo "  MODAL " & sess.Children.Item(CLng(k)).Text
Next
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  WScript.Echo "  [" & ch.Type & "] " & Mid(ch.Id, InStr(ch.Id,"/usr/")+5) & " = '" & ch.Text & "'"
  Err.Clear
  On Error GoTo 0
Next
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
