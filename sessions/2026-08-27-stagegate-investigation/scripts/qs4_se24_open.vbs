Option Explicit
' READ-ONLY QS4/700: open a class in SE24 Display, dump toolbar + control tree,
' and report any ABAP editor control found (so the source pane can be located).
Dim app, conn, s, sess, found, elapsed, i, j, cls, k, ch, ed
cls = UCase(WScript.Arguments(0))
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
CloseModals

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE24"
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
sess.FindById("wnd[0]/usr/ctxtSEOCLASS-CLSNAME").Text = cls
Ready 5000
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
Ready 120000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text
End If

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "PROGRAM|" & sess.Info.Program & "|SCREEN|" & sess.Info.ScreenNumber
WScript.Echo "--- tbar[1] buttons ---"
For k = 0 To 45
  On Error Resume Next
  Set ch = Nothing
  Set ch = sess.FindById("wnd[0]/tbar[1]/btn[" & k & "]")
  If Err.Number = 0 And Not ch Is Nothing Then
    If Len(ch.Tooltip) > 0 Then WScript.Echo "  btn[" & k & "] tip='" & ch.Tooltip & "'"
  End If
  Err.Clear
  On Error GoTo 0
Next
WScript.Echo "--- usr tree ---"
Walk sess.FindById("wnd[0]/usr"), 0

Sub Walk(node, depth)
  Dim n, child, ty, tx
  If depth > 7 Then Exit Sub
  On Error Resume Next
  ty = node.Type : tx = ""
  If ty = "GuiLabel" Or ty = "GuiButton" Or ty = "GuiTab" Then tx = " '" & node.Text & "'"
  If ty = "GuiTextedit" Or (ty = "GuiShell" And node.SubType = "TextEdit") Then
    tx = tx & " [TEXTLEN=" & Len(node.Text) & "]"
  End If
  WScript.Echo Space(depth*2) & "[" & ty & "/" & node.SubType & "] " & Replace(node.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & tx
  If node.ContainerType = True Then
    For n = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(n))
      Walk child, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub

Sub CloseModals()
  Dim guard : guard = 0
  Do While sess.Children.Count > 1 And guard < 8
    sess.FindById("wnd[" & (sess.Children.Count - 1) & "]").SendVKey 12
    Ready 10000
    guard = guard + 1
  Loop
End Sub
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
