Option Explicit
' READ-ONLY: SMICM -> Goto -> Services (Shift+F1). Dumps the ICM service list
' so the external HTTP/HTTPS host and port can be read. No changes are made.
Dim sapGuiAuto, app, sess, elapsed, i, j, conn, s, found, g, cols, r, c, line, v

Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_200_SESSION" : WScript.Quit 9

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n" & WScript.Arguments(0)
sess.FindById("wnd[0]").SendVKey 0
Ready 120000

If WScript.Arguments.Count > 1 Then sess.FindById("wnd[0]").SendVKey CLng(WScript.Arguments(1))
Ready 120000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text

Set g = FindGrid(sess.FindById("wnd[0]/usr"), 0)
If Not g Is Nothing Then
  Set cols = g.ColumnOrder
  WScript.Echo "ALV|rows=" & g.RowCount
  line = ""
  For c = 0 To cols.Count - 1
    line = line & cols(c) & vbTab
  Next
  WScript.Echo "HDR|" & line
  For r = 0 To g.RowCount - 1
    line = ""
    For c = 0 To cols.Count - 1
      v = ""
      On Error Resume Next
      v = g.GetCellValue(CLng(r), cols(c))
      Err.Clear
      On Error GoTo 0
      line = line & v & vbTab
    Next
    WScript.Echo "ROW" & r & "|" & line
  Next
Else
  WScript.Echo "NO_GRID - dumping labels"
  Walk sess.FindById("wnd[0]/usr"), 0
End If

Function FindGrid(node, depth)
  Dim k, child, res
  Set FindGrid = Nothing
  If depth > 8 Then Exit Function
  On Error Resume Next
  If node.Type = "GuiShell" Then
    If node.SubType = "GridView" Then Set FindGrid = node : Exit Function
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Set res = FindGrid(child, depth + 1)
      If Not res Is Nothing Then Set FindGrid = res : Exit Function
    Next
  End If
  On Error GoTo 0
End Function

Sub Walk(node, depth)
  Dim n, c2, id2
  On Error Resume Next
  If node.ContainerType = True Then
    For n = 0 To node.Children.Count - 1
      Set c2 = node.Children.Item(CLng(n))
      Walk c2, depth + 1
    Next
  Else
    id2 = node.Id
    id2 = Mid(id2, InStr(id2, "/usr/") + 5)
    If Len(Trim(node.Text)) > 0 Then WScript.Echo "  " & id2 & " = " & node.Text
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
  WScript.Sleep 900
End Sub
