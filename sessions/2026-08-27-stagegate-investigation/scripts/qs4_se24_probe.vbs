Option Explicit
' READ-ONLY: land on SE24 initial screen with class name typed; dump buttons+menus. Presses nothing.
Dim app, conn, s, sess, found, elapsed, i, j, cls, k, ch, a, b, m1, m2
cls = UCase(WScript.Arguments(0))
Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_QS4_700" : WScript.Quit 9
Do While sess.Children.Count > 1
  sess.FindById("wnd[" & (sess.Children.Count - 1) & "]").SendVKey 12
  Ready 10000
Loop

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE24"
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
sess.FindById("wnd[0]/usr/ctxtSEOCLASS-CLSNAME").Text = cls
Ready 5000
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text & "|PROG=" & sess.Info.Program & "|SCR=" & sess.Info.ScreenNumber
WScript.Echo "--- tbar[1] ---"
For k = 0 To 45
  On Error Resume Next
  Set ch = Nothing
  Set ch = sess.FindById("wnd[0]/tbar[1]/btn[" & k & "]")
  If Err.Number = 0 And Not ch Is Nothing Then
    If Len(ch.Tooltip) > 0 Or Len(ch.Text) > 0 Then WScript.Echo "  btn[" & k & "] text='" & ch.Text & "' tip='" & ch.Tooltip & "'"
  End If
  Err.Clear
  On Error GoTo 0
Next
WScript.Echo "--- menus ---"
On Error Resume Next
For a = 0 To 5
  Set m1 = Nothing
  Set m1 = sess.FindById("wnd[0]/mbar/menu[" & a & "]")
  If Err.Number = 0 And Not m1 Is Nothing Then
    WScript.Echo "menu[" & a & "]=" & m1.Text
    For b = 0 To 15
      Set m2 = Nothing
      Set m2 = sess.FindById("wnd[0]/mbar/menu[" & a & "]/menu[" & b & "]")
      If Err.Number = 0 And Not m2 Is Nothing Then WScript.Echo "   [" & a & "][" & b & "]=" & m2.Text
      Err.Clear
    Next
  End If
  Err.Clear
Next
On Error GoTo 0

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
