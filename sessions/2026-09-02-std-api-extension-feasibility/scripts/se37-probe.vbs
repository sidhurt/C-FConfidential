Option Explicit
' READ-ONLY PROBE. Opens SE37 test screen for BAPI_GOODSMVT_CREATE and dumps the controls.
' DOES NOT EXECUTE ANYTHING. No F8 is pressed.

Dim SapGuiAuto, app, conn, s, sess, i, j, found

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine

WScript.Echo "Connections=" & app.Children.Count
Set conn = app.Children(0)
WScript.Echo "Sessions=" & conn.Children.Count
For j = 0 To conn.Children.Count - 1
  Set s = conn.Children(CLng(j))
  WScript.Echo "  ses[" & j & "] sys=" & s.Info.SystemName & "/" & s.Info.Client & _
               " tcode=" & s.Info.Transaction & " title=" & s.FindById("wnd[0]").Text
Next

' use session 0
Set sess = conn.Children(0)
If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT modal open: " & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
sess.FindById("wnd[0]").SendVKey 0
WScript.Sleep 1500

sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = "BAPI_GOODSMVT_CREATE"
sess.FindById("wnd[0]").SendVKey 0
WScript.Sleep 800

' F8 on the SE37 initial screen opens the TEST screen (does not execute the FM)
sess.FindById("wnd[0]").SendVKey 8
WScript.Sleep 2500

WScript.Echo "----"
WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text
WScript.Echo "PROGRAM=" & sess.Info.Program & " SCREEN=" & sess.Info.ScreenNumber
If sess.Children.Count > 1 Then WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text

Dump sess.FindById("wnd[0]/usr"), 0

Sub Dump(node, depth)
  Dim k, kid, t, nm
  On Error Resume Next
  t = "" : nm = ""
  t = node.Type
  nm = node.Text
  WScript.Echo Space(depth) & node.Id & " [" & t & "] '" & Left(nm, 45) & "'"
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set kid = node.Children.Item(CLng(k))
      Dump kid, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub
