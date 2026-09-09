Option Explicit
' READ-ONLY: probe the SE16N selection-field table control on the CURRENT screen.
Dim app, conn, s, sess, found, i, j, tc, tcId, r, k, ch, n
Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_QS4_700" : WScript.Quit 9
WScript.Echo "TCODE|" & sess.Info.Transaction & "|PROG=" & sess.Info.Program & "|SCR=" & sess.Info.ScreenNumber & "|TITLE=" & sess.FindById("wnd[0]").Text
WScript.Echo "WINDOWS|" & sess.Children.Count
On Error Resume Next
WScript.Echo "GD-TAB|" & sess.FindById("wnd[0]/usr/ctxtGD-TAB").Text
Err.Clear
tcId = "wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC"
Set tc = Nothing
Set tc = sess.FindById(tcId)
If Err.Number <> 0 Or tc Is Nothing Then
  WScript.Echo "NO_TC|" & Err.Description
  Err.Clear
Else
  WScript.Echo "TC|VisibleRowCount=" & tc.VisibleRowCount & "|RowCount=" & tc.RowCount & "|ScrollMax=" & tc.VerticalScrollbar.Maximum & "|ScrollPos=" & tc.VerticalScrollbar.Position
  ' dump the child ids of the first two visible rows
  n = 0
  For k = 0 To tc.Children.Count - 1
    Set ch = Nothing
    Set ch = tc.Children.Item(CLng(k))
    If Err.Number = 0 And Not ch Is Nothing Then
      WScript.Echo "  CHILD|" & ch.Type & "|" & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC/", "") & "|Text=" & ch.Text
      n = n + 1
      If n > 24 Then Exit For
    End If
    Err.Clear
  Next
End If
Err.Clear
On Error GoTo 0
