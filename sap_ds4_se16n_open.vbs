Option Explicit
Dim SapGuiAuto, app, conn, sess, w0, i, c, root
Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children.Item(1)
Set sess = conn.Children.Item(0)
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then WScript.Echo "STOP|wrong session" : WScript.Quit 11
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal before start" : WScript.Quit 12
WScript.Echo "BEFORE|" & sess.Info.Transaction & "|" & sess.FindById("wnd[0]").Text
sess.StartTransaction "SE16N"
Do While sess.Busy
  WScript.Sleep 200
Loop
WScript.Sleep 500
WScript.Echo "AFTER_CHILDREN=" & sess.Children.Count
For Each w0 In sess.Children
  WScript.Echo "WINDOW|" & i & "|" & w0.Name & "|" & w0.Text
  i = i + 1
Next
If sess.Children.Count <> 1 Then WScript.Echo "STOP|unexpected modal after start" : WScript.Quit 13
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
