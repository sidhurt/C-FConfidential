Option Explicit
' Focus the ABAP editor control in the current QS4/700 screen. Reads nothing, changes nothing.
Dim app, conn, s, sess, found, i, j, ed
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
Set ed = Nothing
FindEditor sess.FindById("wnd[0]/usr")
If ed Is Nothing Then WScript.Echo "NO_EDITOR" : WScript.Quit 12
ed.SetFocus
WScript.Echo "FOCUS_OK|" & ed.Id

Sub FindEditor(node)
  Dim n, child, ty, st, isC
  On Error Resume Next
  ty = "" : ty = node.Type
  st = "" : st = node.SubType
  Err.Clear
  If ty = "GuiTextedit" Or st = "TextEdit" Or st = "AbapEditor" Then
    Set ed = node : Exit Sub
  End If
  isC = False : isC = node.ContainerType : Err.Clear
  If isC = True Then
    For n = 0 To node.Children.Count - 1
      Set child = Nothing
      Set child = node.Children.Item(CLng(n))
      If Err.Number = 0 And Not child Is Nothing And ed Is Nothing Then FindEditor child
      Err.Clear
    Next
  End If
  On Error GoTo 0
End Sub
