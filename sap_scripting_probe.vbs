Option Explicit
Dim SapGuiAuto, application, connection, session
On Error Resume Next
Set SapGuiAuto = GetObject("SAPGUI")
If Err.Number <> 0 Then
  WScript.Echo "ERR GetObject " & Err.Number & " " & Err.Description
  WScript.Quit 2
End If
Set application = SapGuiAuto.GetScriptingEngine
If Err.Number <> 0 Then
  WScript.Echo "ERR Engine " & Err.Number & " " & Err.Description
  WScript.Quit 3
End If
WScript.Echo "CONNECTIONS=" & application.Children.Count
Dim i, j
i = 0
For Each connection In application.Children
  WScript.Echo "CONN|" & i & "|" & connection.Description & "|CHILDREN=" & connection.Children.Count
  j = 0
  For Each session In connection.Children
    WScript.Echo "ROW|" & i & "|" & j & "|" & session.Info.SystemName & "|" & session.Info.Client & "|" & session.Info.User & "|" & session.Info.Transaction & "|" & session.Id & "|" & connection.Description
    j = j + 1
  Next
  i = i + 1
Next
