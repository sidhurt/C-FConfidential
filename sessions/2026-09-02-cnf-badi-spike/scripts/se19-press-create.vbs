Option Explicit
Dim sapGuiAuto, application, connection, session
Set sapGuiAuto = GetObject("SAPGUI")
Set application = sapGuiAuto.GetScriptingEngine
Set connection = application.Children.Item(CLng(0))
Set session = connection.Children.Item(CLng(0))
If session.Info.SystemName <> "QS4" Or session.Info.Client <> "700" Then WScript.Quit 2
session.FindById("wnd[0]/usr/btnPUSHBUTTON_IMPLEMENT_TEXT").Press
WScript.Sleep 1000
WScript.Echo "OK title=" & session.FindById("wnd[0]").Text & " windows=" & session.Children.Count
