Option Explicit
' Set the 'accept' request header in /IWFND/GW_CLIENT. Usage: <value>
Dim app, conn, s, sess, found, elapsed, i, j, g, r, nm, val, w, k, ch
val = WScript.Arguments(0)
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
If sess.Info.Transaction <> "/IWFND/GW_CLIENT" Then WScript.Echo "ABORT|NOT_GW_CLIENT" : WScript.Quit 10

Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[0]/shell")
For r = 0 To g.RowCount - 1
  nm = LCase(g.GetCellValue(CLng(r), "NAME"))
  If nm = "accept" Then
    g.CurrentCellRow = CLng(r)
    g.SelectedRows = CStr(r)
    WScript.Echo "SELECTED_ROW|" & r & "|was=" & g.GetCellValue(CLng(r), "VALUE")
    Exit For
  End If
Next

g.PressToolbarButton "CHANGE_HEADER"
Ready 30000

If sess.Children.Count > 1 Then
  Set w = sess.FindById("wnd[1]")
  WScript.Echo "MODAL|" & w.Text
  ' dump the modal fields
  Dim filled : filled = False
  DumpAndFill w, 0, val, filled
  WScript.Echo "FILLED|" & filled
  w.SendVKey 0
  Ready 30000
  If sess.Children.Count > 1 Then
    WScript.Echo "MODAL_STILL|" & sess.FindById("wnd[1]").Text
  End If
Else
  WScript.Echo "NO_MODAL"
End If

Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[0]/shell")
For r = 0 To g.RowCount - 1
  WScript.Echo "NOW|ROW" & r & "|" & g.GetCellValue(CLng(r), "NAME") & "=" & g.GetCellValue(CLng(r), "VALUE")
Next

Sub DumpAndFill(node, depth, v, ByRef done)
  Dim n, child, ty
  On Error Resume Next
  ty = node.Type
  If ty = "GuiTextField" Or ty = "GuiCTextField" Then
    WScript.Echo Space(depth*2) & "FIELD|" & node.Id & "|text=" & node.Text & "|changeable=" & node.Changeable
    If node.Changeable = True And done = False And InStr(LCase(node.Text), "json") > 0 Then
      node.Text = v
      done = True
      WScript.Echo Space(depth*2) & "  -> SET to " & v
    End If
  End If
  If node.ContainerType = True Then
    For n = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(n))
      DumpAndFill child, depth + 1, v, done
    Next
  End If
  On Error GoTo 0
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
