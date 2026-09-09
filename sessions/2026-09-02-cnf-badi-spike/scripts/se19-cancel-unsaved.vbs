Option Explicit
Dim sapGuiAuto, application, connection, session
Set sapGuiAuto = GetObject("SAPGUI")
Set application = sapGuiAuto.GetScriptingEngine
Set connection = application.Children.Item(CLng(0))
Set session = connection.Children.Item(CLng(0))
If session.Info.SystemName <> "QS4" Or session.Info.Client <> "700" Then WScript.Quit 2
If session.Children.Count > 2 Then session.FindById("wnd[2]/tbar[0]/btn[12]").Press
WScript.Sleep 300
If session.Children.Count > 1 Then session.FindById("wnd[1]/tbar[0]/btn[12]").Press
WScript.Sleep 300
WScript.Echo "CLEAN title=" & session.FindById("wnd[0]").Text & " windows=" & session.Children.Count
