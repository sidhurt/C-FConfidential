Option Explicit
' READ-ONLY: dump current /IWFND/GW_CLIENT screen state, incl. request/response header grids.
Dim app, conn, s, sess, found, i, j, elapsed

Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_QS4_700_SESSION" : WScript.Quit 9

WScript.Echo "TCODE|" & sess.Info.Transaction & "|TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "WINDOWS|" & sess.Children.Count
For i = 1 To sess.Children.Count - 1
  WScript.Echo "MODAL|" & sess.Children.Item(CLng(i)).Text
Next
Walk sess.FindById("wnd[0]/usr"), 0

Sub Walk(node, depth)
  Dim k, child, t, st, id, v, cols, r, c, line
  If depth > 9 Then Exit Sub
  On Error Resume Next
  t = node.Type : st = node.SubType : id = node.Id
  If Err.Number <> 0 Then Err.Clear : Exit Sub
  id = Replace(id, "/app/con[0]/ses[0]/wnd[0]/usr/", "")
  If t = "GuiShell" And st = "GridView" Then
    Set cols = node.ColumnOrder
    WScript.Echo Space(depth*2) & "GRID|" & id & "|title=" & node.Title & "|rows=" & node.RowCount
    For r = 0 To node.RowCount - 1
      If r > 60 Then Exit For
      line = ""
      For c = 0 To cols.Count - 1
        v = "" : v = node.GetCellValue(CLng(r), CStr(cols(c))) : Err.Clear
        line = line & cols(c) & "=" & v & "  "
      Next
      WScript.Echo Space(depth*2) & "  ROW" & r & "| " & line
    Next
    Err.Clear
  ElseIf t = "GuiShell" And st = "TextEdit" Then
    v = "" : v = node.Text : Err.Clear
    WScript.Echo Space(depth*2) & "TEXTEDIT|" & id & "|len=" & Len(v) & "|" & Left(Replace(Replace(v,vbCr," "),vbLf," "), 300)
  ElseIf t = "GuiRadioButton" Then
    WScript.Echo Space(depth*2) & "RADIO|" & id & "|sel=" & node.Selected & "|" & node.Text
  ElseIf t = "GuiCheckBox" Then
    WScript.Echo Space(depth*2) & "CHK|" & id & "|sel=" & node.Selected & "|" & node.Text
  End If
  Err.Clear
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Walk child, depth + 1
    Next
  End If
  Err.Clear
  On Error GoTo 0
End Sub
