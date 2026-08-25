Option Explicit
' READ-ONLY: SE37 -> display source of a function module in DS4/200.
' Usage: cscript //nologo ds4_fm_source.vbs <FUNCTION_MODULE>
Dim sapGuiAuto, app, sess, elapsed, fm, i, j, conn, s, found, ed

fm = UCase(WScript.Arguments(0))
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_200" : WScript.Quit 9

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = fm
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
' Display (F7)
sess.FindById("wnd[0]").SendVKey 7
Ready 120000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text

Set ed = FindEditor(sess.FindById("wnd[0]/usr"), 0)
If ed Is Nothing Then
  WScript.Echo "NO_EDITOR - dumping node ids:"
  WalkIds sess.FindById("wnd[0]/usr"), 0
Else
  WScript.Echo "TYPE|" & ed.Type
  WScript.Echo "----BEGIN SOURCE----"
  WScript.Echo ed.Text
  WScript.Echo "----END SOURCE----"
End If

Function FindEditor(node, depth)
  Dim k, child, res
  Set FindEditor = Nothing
  If depth > 10 Then Exit Function
  On Error Resume Next
  If node.Type = "GuiTextEdit" Then Set FindEditor = node : Exit Function
  If node.Type = "GuiShell" Then
    If node.SubType = "TextEdit" Then Set FindEditor = node : Exit Function
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Set res = FindEditor(child, depth + 1)
      If Not res Is Nothing Then Set FindEditor = res : Exit Function
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
  WScript.Sleep 900
End Sub

Sub WalkIds(node, depth)
  Dim k, child, sid
  On Error Resume Next
  sid = node.Id
  sid = Mid(sid, InStr(sid, "/usr/") + 5)
  WScript.Echo "  [" & node.Type & "] " & sid
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      WalkIds child, depth + 1
    Next
  End If
  Err.Clear
  On Error GoTo 0
End Sub
