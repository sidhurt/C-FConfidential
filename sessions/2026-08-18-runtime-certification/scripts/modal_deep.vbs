Option Explicit
' Read-only: recursively dump the open modal window's controls.
Dim sapGuiAuto, app, conn, sess
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Children.Count < 2 Then WScript.Echo "NO_MODAL" : WScript.Quit 1
WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text
Walk sess.FindById("wnd[1]"), 0

Sub Walk(node, depth)
  Dim k, child, t, v
  On Error Resume Next
  t = node.Type
  v = ""
  If InStr(t,"Text") > 0 Or t = "GuiLabel" Or t = "GuiButton" Or t = "GuiCheckBox" Then v = node.Text
  WScript.Echo Space(depth*2) & "[" & t & "] " & Replace(node.Id, "/app/con[0]/ses[0]/wnd[1]/", "") & _
    IIfS(Len(v) > 0, " = '" & v & "'", "")
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Walk child, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub
Function IIfS(c,a,b)
  If c Then IIfS = a Else IIfS = b
End Function
