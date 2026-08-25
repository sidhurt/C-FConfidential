Option Explicit
' Executes only the read-only ATP BAPI in DS4/200.
Dim sapGuiAuto, app, conn, sess, elapsed, plant, material, unit
plant = "1002"
material = "000000000015000177"
unit = "TO"
If WScript.Arguments.Count >= 3 Then
  plant = UCase(WScript.Arguments(0))
  material = UCase(WScript.Arguments(1))
  unit = UCase(WScript.Arguments(2))
End If
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then WScript.Echo "REFUSED_SYSTEM" : WScript.Quit 9
If sess.Info.Program <> "SAPMSSY0" Or sess.Info.ScreenNumber <> 120 Then WScript.Echo "REFUSED_SCREEN" : WScript.Quit 8
If sess.FindById("wnd[0]/usr/lbl[29,1]").Text <> "BAPI_MATERIAL_AVAILABILITY" Then WScript.Echo "REFUSED_FM" : WScript.Quit 7
sess.FindById("wnd[0]/usr/txt[34,9]").Text = plant
sess.FindById("wnd[0]/usr/txt[34,10]").Text = material
sess.FindById("wnd[0]/usr/txt[34,11]").Text = unit
sess.FindById("wnd[0]").SendVKey 8
Ready 60000
WScript.Echo "EXECUTED_READ_ONLY|BAPI_MATERIAL_AVAILABILITY|" & plant & "|" & material & "|" & unit
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text & "|PROGRAM=" & sess.Info.Program & "|SCREEN=" & sess.Info.ScreenNumber
WScript.Echo "STATUS|" & sess.FindById("wnd[0]/sbar").Text

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 1000
End Sub
