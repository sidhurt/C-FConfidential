Option Explicit
' Open transaction BP and dump the entry screen so the controls can be identified.
Dim sapGuiAuto, app, conn, sess, elapsed, k, ch, u

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nBP"
sess.FindById("wnd[0]").SendVKey 0
Ready 120000

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "PROGRAM|" & sess.Info.Program & "|SCREEN|" & sess.Info.ScreenNumber
WScript.Echo "WINDOWS|" & sess.Children.Count
If sess.Children.Count > 1 Then WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text

Walk sess.FindById("wnd[0]/usr"), 0

Sub Walk(node, depth)
  Dim k2, child, t, v
  On Error Resume Next
  t = node.Type
  v = ""
  If t = "GuiLabel" Or t = "GuiButton" Or t = "GuiTab" Or InStr(t,"Text") > 0 Then v = node.Text
  If depth < 6 Then
    WScript.Echo Space(depth*2) & "[" & t & "] " & Replace(node.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & _
      IIfS(Len(v) > 0, " = '" & v & "'", "")
  End If
  If node.ContainerType = True And depth < 6 Then
    For k2 = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k2))
      Walk child, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub
Function IIfS(c,a,b)
  If c Then IIfS = a Else IIfS = b
End Function

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 1500
End Sub
