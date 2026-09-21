Option Explicit
' READ-ONLY. Cancels (F12) wnd[1] on the QS4/700 session ONLY if its title equals the
' exact text passed as argument 1. Anything else is reported and left open.
Dim app, conn, s, sess, ci, si, found, want
want = WScript.Arguments(0)
Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For ci = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(ci))
  For si = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(si))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT no QS4/700 session" : WScript.Quit 9
If sess.Children.Count < 2 Then WScript.Echo "NO_MODAL" : WScript.Quit 0
If sess.FindById("wnd[1]").Text <> want Then WScript.Echo "LEFT_OPEN|" & sess.FindById("wnd[1]").Text : WScript.Quit 3
sess.FindById("wnd[1]").SendVKey 12
WScript.Sleep 800
WScript.Echo "CANCELLED|" & want & "|modals_now=" & (sess.Children.Count - 1)
