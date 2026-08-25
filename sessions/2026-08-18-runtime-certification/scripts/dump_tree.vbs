Option Explicit
' READ-ONLY generic SAP GUI component dumper.
' Usage: cscript //nologo dump_tree.vbs [tcode]
Dim sapGuiAuto, app, conn, sess, elapsed, i

Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

WScript.Echo "SYSTEM=" & sess.Info.SystemName & "|CLIENT=" & sess.Info.Client & "|USER=" & sess.Info.User
WScript.Echo "TCODE_BEFORE=" & sess.Info.Transaction & "|WINDOWS=" & sess.Children.Count
For i = 1 To sess.Children.Count - 1
  WScript.Echo "MODAL_BEFORE|wnd[" & i & "]|" & sess.Children.Item(CLng(i)).Text
Next

If WScript.Arguments.Count >= 1 Then
  sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n" & WScript.Arguments(0)
  sess.FindById("wnd[0]").SendVKey 0
  Ready 30000
End If

WScript.Echo "TCODE_AFTER=" & sess.Info.Transaction & "|PROGRAM=" & sess.Info.Program & "|SCREEN=" & sess.Info.ScreenNumber & "|WINDOWS=" & sess.Children.Count
For i = 0 To sess.Children.Count - 1
  WScript.Echo "--- WINDOW wnd[" & i & "] : " & sess.Children.Item(CLng(i)).Text
  Walk sess.Children.Item(CLng(i)), 0
Next

Sub Walk(node, depth)
  Dim k, child, t, v
  On Error Resume Next
  t = node.Type
  v = ""
  If t = "GuiTextField" Or t = "GuiCTextField" Or t = "GuiLabel" Or t = "GuiButton" Or t = "GuiRadioButton" Or t = "GuiCheckBox" Or t = "GuiTab" Or t = "GuiTextEdit" Then
    v = node.Text
    If Len(v) > 90 Then v = Left(v, 90) & "..."
  End If
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
  WScript.Sleep 700
End Sub
