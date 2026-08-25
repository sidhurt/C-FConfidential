Option Explicit
' STEP 2 (navigation only, no execution): SE37 initial -> Display -> F8 single-test screen.
' Stops and describes any unexpected modal. Never closes a modal. Executes no function module.
Dim sapGuiAuto, app, conn, sess, elapsed, i

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "ABORT|WRONG_SYSTEM_OR_CLIENT|" & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_ALREADY_OPEN|" & sess.FindById("wnd[1]").Text
  WScript.Quit 10
End If

' --- Display ---
sess.FindById("wnd[0]/usr/btnBUT3").Press
Ready 60000
If sess.Children.Count > 1 Then
  WScript.Echo "STOP_AFTER_DISPLAY|MODAL|" & sess.FindById("wnd[1]").Text
  WScript.Echo "STOP_AFTER_DISPLAY|SBAR|" & sess.FindById("wnd[0]/sbar").Text
  WScript.Quit 12
End If
WScript.Echo "AFTER_DISPLAY|title=" & sess.FindById("wnd[0]").Text & _
  "|program=" & sess.Info.Program & "|screen=" & sess.Info.ScreenNumber
WScript.Echo "AFTER_DISPLAY|SBAR|" & sess.FindById("wnd[0]/sbar").Text

' --- F8 : single test ---
sess.FindById("wnd[0]").SendVKey 8
Ready 90000
If sess.Children.Count > 1 Then
  WScript.Echo "STOP_AFTER_F8|MODAL|" & sess.FindById("wnd[1]").Text
  WScript.Quit 13
End If
WScript.Echo "AFTER_F8|title=" & sess.FindById("wnd[0]").Text & _
  "|program=" & sess.Info.Program & "|screen=" & sess.Info.ScreenNumber
WScript.Echo "AFTER_F8|SBAR|" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "AFTER_F8|WINDOWS|" & sess.Children.Count

WScript.Echo "--- TEST SCREEN CONTROLS ---"
Walk sess.FindById("wnd[0]/usr"), 0

Sub Walk(node, depth)
  Dim k, child, t, v, nm
  On Error Resume Next
  t = node.Type
  v = "" : nm = ""
  If t = "GuiTextField" Or t = "GuiCTextField" Or t = "GuiLabel" Or t = "GuiButton" _
     Or t = "GuiCheckBox" Or t = "GuiRadioButton" Then
    v = node.Text
  End If
  If t <> "GuiSimpleContainer" Then
    WScript.Echo Space(depth * 2) & "[" & t & "] " & node.Id & IIfStr(Len(v) > 0, " = '" & v & "'", "")
  End If
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
