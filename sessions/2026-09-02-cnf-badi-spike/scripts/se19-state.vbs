Option Explicit
Dim sapGuiAuto, application, connection, session
Set sapGuiAuto = GetObject("SAPGUI")
Set application = sapGuiAuto.GetScriptingEngine
Set connection = application.Children.Item(CLng(0))
Set session = connection.Children.Item(CLng(0))
WScript.Echo "transaction=" & session.Info.Transaction
WScript.Echo "title=" & session.FindById("wnd[0]").Text
WScript.Echo "status=" & session.FindById("wnd[0]/sbar/pane[0]").Text
WScript.Echo "newSelected=" & session.FindById("wnd[0]/usr/radG_IS_NEW_2").Selected
WScript.Echo "spot=" & session.FindById("wnd[0]/usr/ctxtG_ENHSPOTNAME").Text
WScript.Echo "spotEnabled=" & session.FindById("wnd[0]/usr/ctxtG_ENHSPOTNAME").Enabled
WScript.Echo "spotChangeable=" & session.FindById("wnd[0]/usr/ctxtG_ENHSPOTNAME").Changeable
WScript.Echo "spotMaxLength=" & session.FindById("wnd[0]/usr/ctxtG_ENHSPOTNAME").MaxLength
