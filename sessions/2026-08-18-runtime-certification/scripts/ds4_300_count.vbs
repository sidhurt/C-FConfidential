Option Explicit
' READ-ONLY row count in DS4 client 300.
' Usage: ds4_300_count.vbs <TABLE> [selFieldId=VALUE ...]
Dim app, sess, i, j, conn, s, found, elapsed, tbl, k, arg, eq, fid, fval
tbl = UCase(WScript.Arguments(0))
Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "300" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_300" : WScript.Quit 9

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
Accept
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
Accept

For k = 1 To WScript.Arguments.Count - 1
  arg = WScript.Arguments(k)
  eq = InStr(arg, "=")
  If eq > 1 Then
    fid = Left(arg, eq - 1) : fval = Mid(arg, eq + 1)
    On Error Resume Next
    sess.FindById("wnd[0]/usr/" & fid).Text = fval
    If Err.Number <> 0 Then WScript.Echo "  SELFIELD_ERR|" & fid
    Err.Clear
    On Error GoTo 0
  End If
Next

' press the row-count button (Ctrl+F7 = number of entries)
sess.FindById("wnd[0]").SendVKey 31
Ready 180000
If sess.Children.Count > 1 Then
  WScript.Echo tbl & " | " & sess.FindById("wnd[1]").Text & " | " & sess.FindById("wnd[1]/usr/txtMESSTXT1").Text
  sess.FindById("wnd[1]").SendVKey 0
  Ready 20000
Else
  WScript.Echo tbl & " | " & sess.FindById("wnd[0]/sbar").Text
End If

Sub Accept()
  On Error Resume Next
  If sess.Children.Count > 1 Then
    If sess.FindById("wnd[1]").Text = "Select Fields for Selection" Then
      sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
      Ready 30000
    End If
  End If
  Err.Clear
  On Error GoTo 0
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 600
End Sub
