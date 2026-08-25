Option Explicit
' Read-only: dump a submenu's entries.  Usage: menu_sub.vbs <topIdx> <subIdx>
Dim sapGuiAuto, app, conn, sess, a, b, j, m
a = WScript.Arguments(0) : b = WScript.Arguments(1)
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
WScript.Echo "PARENT|" & sess.FindById("wnd[0]/mbar/menu[" & a & "]/menu[" & b & "]").Text
For j = 0 To 25
  On Error Resume Next
  Set m = Nothing
  Set m = sess.FindById("wnd[0]/mbar/menu[" & a & "]/menu[" & b & "]/menu[" & j & "]")
  If Err.Number <> 0 Then Err.Clear : Exit For
  WScript.Echo "  menu[" & a & "]/menu[" & b & "]/menu[" & j & "] = " & m.Text
  On Error GoTo 0
Next
