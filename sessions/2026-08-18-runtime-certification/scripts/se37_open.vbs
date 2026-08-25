Option Explicit
' Read-only SE37 navigator. Opens a function module in Display mode only.
Dim sapGuiAuto, app, conn, sess, fm, elapsed
If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|se37_open.vbs <FUNCTION_MODULE>" : WScript.Quit 1
fm = UCase(WScript.Arguments(0))
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = fm
sess.FindById("wnd[0]/usr/btnBUT3").Press
Ready 40000
WScript.Echo "SESSION|" & sess.Info.SystemName & "|" & sess.Info.Client & "|" & sess.Info.User
WScript.Echo "FM|" & fm
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "TCODE|" & sess.Info.Transaction & "|PROGRAM|" & sess.Info.Program & "|SCREEN|" & sess.Info.ScreenNumber
WScript.Echo "STATUS|" & sess.FindById("wnd[0]/sbar").Text

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 700
End Sub
