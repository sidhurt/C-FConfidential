Option Explicit
Dim SapGuiAuto, app, conn, sess, w0, root, i, c
Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children.Item(1)
Set sess = conn.Children.Item(0)
WScript.Echo "CONFIRM|" & sess.Info.SystemName & "|" & sess.Info.Client & "|" & sess.Info.User & "|" & sess.Info.Transaction & "|" & sess.Id
WScript.Echo "CHILDREN=" & sess.Children.Count
For i = 0 To sess.Children.Count - 1
  On Error Resume Next
  Set w0 = sess.Children.Item(i)
  WScript.Echo "WINDOW|" & i & "|" & w0.Name & "|" & w0.Text & "|TYPE=" & w0.Type
  On Error GoTo 0
Next
If sess.Children.Count <> 1 Then
  WScript.Echo "STOP|unexpected secondary window/modal"
  WScript.Quit 10
End If
Set w0 = sess.FindById("wnd[0]")
WScript.Echo "ROOT|" & w0.Text
Set root = sess.FindById("wnd[0]/usr")
WScript.Echo "USRCHILDREN=" & root.Children.Count
For i = 0 To root.Children.Count - 1
  On Error Resume Next
  Set c = root.Children.Item(i)
  WScript.Echo "CTRL|" & i & "|" & c.Id & "|" & c.Type & "|" & c.Name & "|" & c.Text
  On Error GoTo 0
Next
