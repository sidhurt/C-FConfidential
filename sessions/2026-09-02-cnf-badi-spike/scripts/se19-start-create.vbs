Option Explicit

Dim sapGuiAuto, application, connection, session
Set sapGuiAuto = GetObject("SAPGUI")
Set application = sapGuiAuto.GetScriptingEngine
Set connection = application.Children.Item(CLng(0))
Set session = connection.Children.Item(CLng(0))

If session.Info.SystemName <> "QS4" Or session.Info.Client <> "700" Then
  WScript.Echo "REFUSE system=" & session.Info.SystemName & " client=" & session.Info.Client
  WScript.Quit 2
End If

If session.Info.Transaction <> "SE19" Then session.StartTransaction "SE19"
session.FindById("wnd[0]/usr/radG_IS_NEW_2").Select
session.FindById("wnd[0]/usr/ctxtG_ENHSPOTNAME").Text = "MB_GOODSMOVEMENT"
session.FindById("wnd[0]/usr/btnPUSHBUTTON_IMPLEMENT_TEXT").Press
WScript.Sleep 1000
WScript.Echo "OK title=" & session.FindById("wnd[0]").Text & " windows=" & session.Children.Count
