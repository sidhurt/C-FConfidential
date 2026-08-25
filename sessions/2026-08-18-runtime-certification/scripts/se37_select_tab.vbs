Option Explicit
' Read-only helper: select a Function Builder tab and dump the visible component tree.
Dim sapGuiAuto, app, conn, sess, tabName, tabId, elapsed
If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|se37_select_tab.vbs ATTRIBUTES|IMPORT|EXPORT|CHANGING|TABLES|EXCEPTIONS" : WScript.Quit 1
tabName = UCase(WScript.Arguments(0))
Select Case tabName
  Case "ATTRIBUTES": tabId = "HEADER"
  Case "IMPORT": tabId = "IMPORT"
  Case "EXPORT": tabId = "EXPORT"
  Case "CHANGING": tabId = "CHANGE"
  Case "TABLES": tabId = "TABLES"
  Case "EXCEPTIONS": tabId = "EXCEPT"
  Case Else: WScript.Echo "UNKNOWN_TAB|" & tabName : WScript.Quit 2
End Select
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then WScript.Echo "REFUSED" : WScript.Quit 9
sess.FindById("wnd[0]/usr/tabsFUNC_TAB_STRIP/tabp" & tabId).Select
Ready 20000
WScript.Echo "TAB|" & tabName & "|TITLE|" & sess.FindById("wnd[0]").Text
Walk sess.FindById("wnd[0]/usr/tabsFUNC_TAB_STRIP/tabp" & tabId), 0

Sub Walk(node, depth)
  Dim k, child, t, v, n, tip, c
  If depth > 8 Then Exit Sub
  On Error Resume Next
  t = node.Type : v = "" : n = node.Name : tip = node.Tooltip
  If t = "GuiTextField" Or t = "GuiCTextField" Or t = "GuiLabel" Or t = "GuiButton" Or t = "GuiRadioButton" Or t = "GuiCheckBox" Or t = "GuiTab" Or t = "GuiTextEdit" Then v = node.Text
  If Len(v) > 140 Then v = Left(v, 140) & "..."
  WScript.Echo Space(depth * 2) & "NODE|" & t & "|" & node.Id & "|Name=" & Clean(n) & "|Text=" & Clean(v) & "|Tip=" & Clean(tip)
  Err.Clear
  c = node.Children.Count
  If Err.Number <> 0 Then Err.Clear : Exit Sub
  On Error GoTo 0
  For k = 0 To c - 1
    On Error Resume Next
    Set child = node.Children.Item(CLng(k))
    If Err.Number = 0 Then Walk child, depth + 1
    Err.Clear
    On Error GoTo 0
  Next
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 600
End Sub

Function Clean(v)
  Clean = Replace(Replace(Replace(CStr(v), vbCr, " "), vbLf, " "), "|", "/")
End Function
