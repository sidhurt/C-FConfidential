Option Explicit

Dim sapGuiAuto, application, connection, session, fso, logFile
Set fso = CreateObject("Scripting.FileSystemObject")
Set logFile = fso.CreateTextFile("C:\Users\sidmy\Downloads\shree-cement-cnf-agent-cowork-20260729T062834Z-1-001\shree-cement-cnf-agent-cowork\sessions\2026-09-02-cnf-badi-spike\goto-se19.log", True)
logFile.WriteLine "START"
Set sapGuiAuto = GetObject("SAPGUI")
logFile.WriteLine "GOT_SAPGUI"
Set application = sapGuiAuto.GetScriptingEngine
Set connection = application.Children.Item(CLng(0))
Set session = connection.Children.Item(CLng(0))
logFile.WriteLine "ATTACHED system=" & session.Info.SystemName & " client=" & session.Info.Client

If session.Info.SystemName <> "QS4" Or session.Info.Client <> "700" Then
  WScript.Echo "REFUSE system=" & session.Info.SystemName & " client=" & session.Info.Client
  WScript.Quit 2
End If

session.StartTransaction "SE19"
WScript.Sleep 1000
logFile.WriteLine "OK transaction=" & session.Info.Transaction & " title=" & session.FindById("wnd[0]").Text
logFile.Close
WScript.Echo "OK transaction=" & session.Info.Transaction & " title=" & session.FindById("wnd[0]").Text
