Option Explicit
' Navigates a named system/client to a transaction and dumps the screen.
' USAGE: sap-goto.vbs <SYS> <CLIENT> <TCODE> [DUMP]
Dim app, conn, s, sess, found, i, j, wantSys, wantCli, tcode, doDump, elapsed

If WScript.Arguments.Count < 3 Then WScript.Echo "USAGE|SYS CLIENT TCODE [DUMP]" : WScript.Quit 1
wantSys = UCase(CStr(WScript.Arguments(0)))
wantCli = CStr(WScript.Arguments(1))
tcode   = UCase(CStr(WScript.Arguments(2)))
doDump  = (WScript.Arguments.Count > 3)

Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = wantSys And s.Info.Client = wantCli Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NOT_FOUND" : WScript.Quit 9
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text : WScript.Quit 10

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n" & tcode
sess.FindById("wnd[0]").SendVKey 0
Ready 20000

WScript.Echo "SYSTEM=" & sess.Info.SystemName & "/" & sess.Info.Client
WScript.Echo "TCODE=" & sess.Info.Transaction & " PROGRAM=" & sess.Info.Program & " SCREEN=" & sess.Info.ScreenNumber
WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR=" & sess.FindById("wnd[0]/sbar").Text
If sess.Children.Count > 1 Then WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text

If doDump Then Dump sess.FindById("wnd[0]/usr"), 0

Sub Dump(node, depth)
  Dim k, kid, t, nm, sid
  On Error Resume Next
  t = node.Type : nm = node.Text : sid = node.Id
  sid = Mid(sid, InStr(sid, "wnd[0]/usr") + 10)
  If t <> "GuiLabel" Or Len(Trim(nm)) > 0 Then
    WScript.Echo Space(depth) & sid & " [" & t & "] '" & Left(nm, 45) & "'"
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set kid = node.Children.Item(CLng(k))
      Dump kid, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub

Sub Ready(maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
