Option Explicit
Dim sapGuiAuto, app, sess, elapsed, fm, i, j, conn, s, found, ed, base
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
sess.FindById("wnd[0]").SendVKey 8
Ready 120000

Ready 120000
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text

WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "WINDOWS|" & sess.Children.Count
Dump sess.FindById("wnd[0]/usr"), 0

Sub Dump(node, depth)
  Dim k, child, sid
  On Error Resume Next
  sid = node.Id
  sid = Mid(sid, InStr(sid, "/usr/") + 5)
  If node.ContainerType <> True Then
    If node.Type = "GuiTextField" Or node.Type = "GuiCTextField" Or node.Type = "GuiLabel" Then
      WScript.Echo "  [" & node.Type & "] " & sid & " = '" & node.Text & "'"
    End If
  Else
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Dump child, depth + 1
    Next
  End If
  Err.Clear
  On Error GoTo 0
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
