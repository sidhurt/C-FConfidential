Option Explicit
' READ-ONLY. SE16 <TABLE> with optional field filters; reports the result window title (carries the hit count).
Dim sapGuiAuto, app, conn, sess, elapsed, tbl, i, arg, eq
tbl = UCase(WScript.Arguments(0))
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED " & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
CloseModals
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
For i = 1 To WScript.Arguments.Count - 1
  arg = WScript.Arguments(i)
  eq = InStr(arg, "=")
  If eq > 1 Then
    On Error Resume Next
    sess.FindById("wnd[0]/usr/" & Left(arg, eq-1)).Text = Mid(arg, eq+1)
    If Err.Number <> 0 Then WScript.Echo "FIELD_ERR|" & Left(arg,eq-1) & "|" & Err.Description : Err.Clear
    On Error GoTo 0
  End If
Next
sess.FindById("wnd[0]").SendVKey 8
Ready 180000
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text
CloseModals
Sub CloseModals()
  Dim guard : guard = 0
  Do While sess.Children.Count > 1 And guard < 6
    sess.FindById("wnd[" & (sess.Children.Count-1) & "]").SendVKey 12 : Ready 8000 : guard = guard + 1
  Loop
End Sub
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 600
End Sub
