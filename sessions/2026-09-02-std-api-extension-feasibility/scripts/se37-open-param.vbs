Option Explicit
' Sets TESTRUN = X, then opens a named parameter's entry screen and dumps it.
' Assumes SE37 test screen for BAPI_GOODSMVT_CREATE is already displayed.
' DOES NOT EXECUTE THE FUNCTION MODULE.
' Usage: se37-open-param.vbs <LABEL_ID>   e.g. "lbl[2,10]" for GOODSMVT_CODE

Dim SapGuiAuto, app, conn, sess, target, tr

If WScript.Arguments.Count < 1 Then WScript.Echo "ERR usage: <LABEL_ID>" : WScript.Quit 2
target = WScript.Arguments(0)

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If
If sess.FindById("wnd[0]").Text <> "Test Function Module: Initial Screen" Then
  WScript.Echo "ABORT not on SE37 test screen: " & sess.FindById("wnd[0]").Text : WScript.Quit 10
End If

' SAFETY: TESTRUN must be X before anything else
sess.FindById("wnd[0]/usr/txt[34,11]").Text = "X"
WScript.Sleep 300
tr = sess.FindById("wnd[0]/usr/txt[34,11]").Text
WScript.Echo "TESTRUN=" & tr
If tr <> "X" Then WScript.Echo "ABORT could not set TESTRUN" : WScript.Quit 11

sess.FindById("wnd[0]/usr/" & target).SetFocus
WScript.Sleep 300
sess.FindById("wnd[0]").SendVKey 2      ' F2 = detail / choose
WScript.Sleep 2000

WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text
WScript.Echo "PROGRAM=" & sess.Info.Program & " SCREEN=" & sess.Info.ScreenNumber
If sess.Children.Count > 1 Then WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text

Dump sess.FindById("wnd[0]/usr"), 0

Sub Dump(node, depth)
  Dim k, kid, t, nm
  On Error Resume Next
  t = node.Type : nm = node.Text
  WScript.Echo Space(depth) & node.Id & " [" & t & "] '" & Left(nm, 40) & "'"
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set kid = node.Children.Item(CLng(k))
      Dump kid, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub
