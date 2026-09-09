Option Explicit
' On the SE19 initial screen of a named system/client: select New BAdI,
' enter the enhancement spot, press Create, then dump the resulting screen.
' Creates nothing by itself - the dialog that opens is still unsaved.
' USAGE: se19-create-start.vbs <SYS> <CLIENT> <ENHSPOT>
Dim app, conn, s, sess, found, i, j, wantSys, wantCli, spot, elapsed

If WScript.Arguments.Count < 3 Then WScript.Echo "USAGE|SYS CLIENT ENHSPOT" : WScript.Quit 1
wantSys = UCase(CStr(WScript.Arguments(0)))
wantCli = CStr(WScript.Arguments(1))
spot    = UCase(CStr(WScript.Arguments(2)))

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

If sess.FindById("wnd[0]").Text <> "BAdI Builder: Initial Screen for Implementations" Then
  WScript.Echo "ABORT|NOT_ON_SE19|" & sess.FindById("wnd[0]").Text : WScript.Quit 10
End If

sess.FindById("wnd[0]/usr/radG_IS_NEW_2").Select
WScript.Sleep 400
sess.FindById("wnd[0]/usr/ctxtG_ENHSPOTNAME").Text = spot
WScript.Sleep 400
WScript.Echo "SPOT_SET=" & sess.FindById("wnd[0]/usr/ctxtG_ENHSPOTNAME").Text

sess.FindById("wnd[0]/usr/btnPUSHBUTTON_IMPLEMENT_TEXT").Press
Ready 20000

WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR=" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "WINDOWS=" & sess.Children.Count
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text
  Dump sess.FindById("wnd[1]/usr"), 0
Else
  Dump sess.FindById("wnd[0]/usr"), 0
End If

Sub Dump(node, depth)
  Dim k, kid, t, nm, sid
  On Error Resume Next
  t = node.Type : nm = node.Text : sid = node.Id
  If InStr(sid, "/usr") > 0 Then sid = Mid(sid, InStr(sid, "/usr") + 4)
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
