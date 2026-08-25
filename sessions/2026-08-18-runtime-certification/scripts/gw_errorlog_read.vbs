Option Explicit
' Run /IWFND/ERROR_LOG selection and dump the newest entries.
Dim sapGuiAuto, app, conn, sess, elapsed, g, cols, r, c, line, v, n

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If

Ready 3000 ': skipped F8
Ready 180000
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 13
End If

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text

Set g = FindGrid(sess.FindById("wnd[0]/usr"), 0)
If g Is Nothing Then WScript.Echo "NO_GRID" : WScript.Quit 0

Set cols = g.ColumnOrder
WScript.Echo "ROWS|" & g.RowCount
line = ""
For c = 0 To cols.Count - 1
  line = line & cols(c) & vbTab
Next
WScript.Echo "HDR|" & line
n = g.RowCount - 1
If n > 4 Then n = 4
For r = 0 To n
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

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 1200
End Sub
