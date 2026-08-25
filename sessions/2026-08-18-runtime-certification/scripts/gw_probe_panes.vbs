Option Explicit
' READ-ONLY. Executes one GET in /IWFND/GW_CLIENT and reports the identity of each splitter pane.
Dim sapGuiAuto, app, conn, sess, elapsed, i, base, sh, t
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "ERROR: wrong system/client " & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If

If sess.Info.Transaction <> "/IWFND/GW_CLIENT" Then
  sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n/IWFND/GW_CLIENT"
  sess.FindById("wnd[0]").SendVKey 0
  Ready 30000
End If

sess.FindById("wnd[0]/usr/radRB_GET").Select
sess.FindById("wnd[0]/usr/cntlURI_AREA/shellcont/shell").Text = WScript.Arguments(0)
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
Ready 120000

WScript.Echo "SBAR=" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "WINDOWS=" & sess.Children.Count
base = "wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont["
For i = 0 To 5
  On Error Resume Next
  Set sh = Nothing
  Set sh = sess.FindById(base & i & "]/shell")
  If Err.Number = 0 And Not sh Is Nothing Then
    t = ""
    t = sh.Text
    WScript.Echo "PANE[" & i & "]|Type=" & sh.Type & "|SubType=" & sh.SubType & "|Len=" & Len(t)
    WScript.Echo "PANE[" & i & "]|FIRST200=" & Replace(Replace(Left(t, 200), vbCr, " "), vbLf, " ")
  Else
    WScript.Echo "PANE[" & i & "]|absent (" & Err.Description & ")"
  End If
  Err.Clear
  On Error GoTo 0
Next

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
