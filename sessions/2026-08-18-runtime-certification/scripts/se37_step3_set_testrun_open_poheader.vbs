Option Explicit
' STEP 3 (input only, no execution): set TESTRUN = X, then drill into the POHEADER
' structure on the SE37 single-test screen and dump its entry fields.
' Does not press F8. Does not close modals.
Dim sapGuiAuto, app, conn, sess, elapsed

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
If sess.FindById("wnd[0]").Text <> "Test Function Module: Initial Screen" Then
  WScript.Echo "ABORT|UNEXPECTED_SCREEN|" & sess.FindById("wnd[0]").Text
  WScript.Quit 11
End If

' --- TESTRUN = X ---
sess.FindById("wnd[0]/usr/txt[34,12]").Text = "X"
Ready 15000
WScript.Echo "SET|wnd[0]/usr/txt[34,12]|TESTRUN|X|readback='" & sess.FindById("wnd[0]/usr/txt[34,12]").Text & "'"

' --- drill into POHEADER (label at row 9) ---
sess.FindById("wnd[0]/usr/lbl[2,9]").SetFocus
sess.FindById("wnd[0]/usr/lbl[2,9]").CaretPosition = 3
sess.FindById("wnd[0]").SendVKey 2
Ready 60000

If sess.Children.Count > 1 Then
  WScript.Echo "STOP|UNEXPECTED_MODAL|" & sess.FindById("wnd[1]").Text
  WScript.Quit 12
End If

WScript.Echo "AFTER_DRILL|title=" & sess.FindById("wnd[0]").Text & _
  "|program=" & sess.Info.Program & "|screen=" & sess.Info.ScreenNumber
WScript.Echo "AFTER_DRILL|SBAR|" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "--- POHEADER STRUCTURE FIELDS ---"
Walk sess.FindById("wnd[0]/usr"), 0

Sub Walk(node, depth)
  Dim k, child, t, v
  On Error Resume Next
  t = node.Type
  v = ""
  If t = "GuiTextField" Or t = "GuiCTextField" Or t = "GuiLabel" Or t = "GuiCheckBox" Then v = node.Text
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
