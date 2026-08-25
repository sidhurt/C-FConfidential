Option Explicit
' Guards DS4/200 and puts keyboard focus in the GW_CLIENT request-body editor.
Dim sapGuiAuto, app, conn, sess
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED " & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "REFUSED modal open: " & sess.FindById("wnd[1]").Text
  WScript.Quit 10
End If
sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[2]/shell").SetFocus
WScript.Echo "FOCUS_OK " & sess.Info.SystemName & "/" & sess.Info.Client & " " & sess.Info.Transaction
