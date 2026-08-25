Option Explicit
' READ-ONLY: open a class in SE24 Display and dump the control tree so the
' source-display control can be identified. Navigates only; changes nothing.
Dim sapGuiAuto, app, conn, sess, cls, elapsed, k, ch

If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|<CLASS>" : WScript.Quit 1
cls = UCase(WScript.Arguments(0))

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE24"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtSEOCLASS-CLSNAME").Text = cls
Ready 5000
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press   ' Display
Ready 90000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text & "|left open"
  WScript.Quit 13
End If

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "PROGRAM|" & sess.Info.Program & "|SCREEN|" & sess.Info.ScreenNumber
WScript.Echo "--- controls ---"
Walk sess.FindById("wnd[0]/usr"), 0
WScript.Echo "--- tbar[1] ---"
For k = 0 To 50
  On Error Resume Next
  Set ch = Nothing
  Set ch = sess.FindById("wnd[0]/tbar[1]/btn[" & k & "]")
  If Err.Number = 0 And Not ch Is Nothing Then
    WScript.Echo "  btn[" & k & "] text='" & ch.Text & "' tip='" & ch.Tooltip & "'"
  End If
  Err.Clear
  On Error GoTo 0
Next

Sub Walk(node, depth)
  Dim k2, child, t, v
  On Error Resume Next
  t = node.Type
  v = ""
  If t = "GuiLabel" Or t = "GuiButton" Or t = "GuiTab" Then v = node.Text
  WScript.Echo Space(depth * 2) & "[" & t & "/" & node.SubType & "] " & _
    Replace(node.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & IIfStr(Len(v) > 0, " = '" & v & "'", "")
  If node.ContainerType = True Then
    For k2 = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k2))
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
