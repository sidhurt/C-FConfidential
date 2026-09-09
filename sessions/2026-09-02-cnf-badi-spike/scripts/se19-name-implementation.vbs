Option Explicit
Dim sapGuiAuto, application, connection, session
Set sapGuiAuto = GetObject("SAPGUI")
Set application = sapGuiAuto.GetScriptingEngine
Set connection = application.Children.Item(CLng(0))
Set session = connection.Children.Item(CLng(0))
If session.Info.SystemName <> "QS4" Or session.Info.Client <> "700" Then WScript.Quit 2

If session.Children.Count > 2 Then session.FindById("wnd[2]/tbar[0]/btn[0]").Press
session.FindById("wnd[1]/usr/txtG_ENHSTRU-ENHNAME").Text = "ZCNF_SUBMIT_MIGO"
session.FindById("wnd[1]/usr/txtG_ENHSTRU-SHORTTEXT").Text = "CNF delivery-based Submit MIGO"
session.FindById("wnd[1]/tbar[0]/btn[0]").Press
WScript.Sleep 1000
WScript.Echo "OK title=" & session.FindById("wnd[0]").Text & " windows=" & session.Children.Count
