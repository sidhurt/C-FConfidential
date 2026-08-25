Option Explicit
Dim app, i, j, conn, s
Set app = GetObject("SAPGUI").GetScriptingEngine
WScript.Echo "Connections=" & app.Children.Count
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    WScript.Echo "  [" & i & "," & j & "] " & s.Info.SystemName & "/" & s.Info.Client & _
                 "  user=" & s.Info.User & "  tcode=" & s.Info.Transaction
  Next
Next
