Option Explicit
' Read-only: SE37 -> <FM> -> Display -> Source code tab -> dump ABAP editor text to file.
' Creates nothing, changes nothing, executes no function module.
' USAGE: se37_dump_source.vbs <FUNCTION_MODULE> <OUTFILE>
Dim sapGuiAuto, app, conn, sess, fm, outf, elapsed, fso, ts, ed, tabs, i, tab, hit

If WScript.Arguments.Count < 2 Then
  WScript.Echo "USAGE|se37_dump_source.vbs <FM> <OUTFILE>" : WScript.Quit 1
End If
fm   = UCase(WScript.Arguments(0))
outf = WScript.Arguments(1)

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

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = fm
sess.FindById("wnd[0]/usr/btnBUT3").Press          ' Display
Ready 60000

If sess.Children.Count > 1 Then
  WScript.Echo "STOP|MODAL_AFTER_DISPLAY|" & sess.FindById("wnd[1]").Text : WScript.Quit 12
End If
WScript.Echo "AFTER_DISPLAY|" & sess.FindById("wnd[0]").Text & "|prog=" & sess.Info.Program & "|scr=" & sess.Info.ScreenNumber

' --- find the tabstrip and select the tab whose caption starts with "Source" ---
hit = 0
FindTabs sess.FindById("wnd[0]/usr")
If hit = 0 Then WScript.Echo "NOTE|no Source tab found; dumping whatever editor is visible"

' --- walk for the ABAP editor control and dump it ---
Set ed = Nothing
FindEditor sess.FindById("wnd[0]/usr")
If ed Is Nothing Then
  WScript.Echo "FAIL|no GuiTextedit found"
  WScript.Echo "--- CONTROL TREE ---"
  Walk sess.FindById("wnd[0]/usr"), 0
  WScript.Quit 13
End If

Set fso = CreateObject("Scripting.FileSystemObject")
Set ts  = fso.CreateTextFile(outf, True, True)
ts.Write ed.Text
ts.Close
WScript.Echo "OK|" & fm & "|chars=" & Len(ed.Text) & "|lines=" & (UBound(Split(ed.Text, vbCr)) + 1) & "|" & outf

Sub FindTabs(node)
  Dim k, child
  On Error Resume Next
  If node.Type = "GuiTabStrip" Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      If InStr(1, child.Text, "Source", 1) = 1 Or InStr(1, child.Text, "Quellt", 1) = 1 Then
        child.Select
        Ready 30000
        WScript.Echo "TAB|selected '" & child.Text & "'"
        hit = 1
        Exit Sub
      End If
    Next
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      If hit = 0 Then FindTabs child
    Next
  End If
  On Error GoTo 0
End Sub

Sub FindEditor(node)
  Dim k, child
  On Error Resume Next
  If node.Type = "GuiTextedit" Then
    Set ed = node
    Exit Sub
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      If ed Is Nothing Then FindEditor child
    Next
  End If
  On Error GoTo 0
End Sub

Sub Walk(node, depth)
  Dim k, child
  On Error Resume Next
  WScript.Echo Space(depth * 2) & "[" & node.Type & "] " & node.Id
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Walk child, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 700
End Sub
