Option Explicit
' READ-ONLY on SAP. Triggers Download to PC and dumps the resulting dialog structure.
Dim sapGuiAuto, app, conn, sess, elapsed, i
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

sess.FindById("wnd[0]/mbar/menu[0]/menu[0]").Select
Ready 15000

WScript.Echo "WINDOWS=" & sess.Children.Count
For i = 0 To sess.Children.Count - 1
  WScript.Echo "--- wnd[" & i & "] Type=" & sess.Children.Item(CLng(i)).Type & " Text=" & sess.Children.Item(CLng(i)).Text
Next
If sess.Children.Count > 1 Then Walk sess.FindById("wnd[1]"), 0

Sub Walk(node, depth)
  Dim k, child, t, v
  On Error Resume Next
  t = node.Type
  v = ""
  If InStr(t, "Text") > 0 Or t = "GuiLabel" Or t = "GuiButton" Or t = "GuiRadioButton" Or t = "GuiCheckBox" Or t = "GuiComboBox" Then v = node.Text
  WScript.Echo Space(depth * 2) & "[" & t & "] " & node.Id & IIfStr(Len(v) > 0, " = '" & v & "'", "")
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Walk child, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub
Function IIfStr(c, a, b)
  If c Then IIfStr = a Else IIfStr = b
End Function
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
