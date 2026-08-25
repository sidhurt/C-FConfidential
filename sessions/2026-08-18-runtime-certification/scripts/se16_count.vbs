Option Explicit
' READ-ONLY. SE16 row count for a table in DS4/200. Usage: se16_count.vbs <TABLE>
Dim sapGuiAuto, app, conn, sess, elapsed, tbl, i
tbl = UCase(WScript.Arguments(0))
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED " & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
Dim guard : guard = 0
Do While sess.Children.Count > 1 And guard < 6
  sess.FindById("wnd[" & (sess.Children.Count-1) & "]").SendVKey 12 : Ready 8000 : guard = guard + 1
Loop
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
' number-of-entries button is Ctrl+F7 (VKey 19) on the selection screen
sess.FindById("wnd[0]").SendVKey 19
Ready 120000
WScript.Echo "TABLE=" & tbl & "|SBAR=" & sess.FindById("wnd[0]/sbar").Text & "|WINDOWS=" & sess.Children.Count
For i = 1 To sess.Children.Count - 1
  WScript.Echo "MODAL|" & sess.Children.Item(CLng(i)).Text
  On Error Resume Next
  Dim j, ch
  For j = 0 To 30
    Set ch = Nothing
    Set ch = sess.FindById("wnd[" & i & "]/usr/txtG_DBCOUNT")
    If Err.Number = 0 Then WScript.Echo "  COUNT=" & ch.Text : Err.Clear : Exit For
    Err.Clear
    Exit For
  Next
  ' generic: dump labels in the modal
  Dim u : Set u = sess.FindById("wnd[" & i & "]/usr")
  For j = 0 To u.Children.Count - 1
    WScript.Echo "  [" & u.Children.Item(CLng(j)).Type & "] " & u.Children.Item(CLng(j)).Text
  Next
  On Error GoTo 0
Next
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 700
End Sub
