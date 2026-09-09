Option Explicit
' READ-ONLY. In an already-open ABAP editor display screen, opens Find (Ctrl+F),
' searches for a string, and leaves the view positioned on the match.
' Usage: find-in-editor.vbs <SEARCHSTRING> [PROBE]
' With PROBE as 2nd arg, dumps the modal's controls instead of searching.

Dim SapGuiAuto, app, conn, sess, needle, probe, i, ch, kids

If WScript.Arguments.Count < 1 Then WScript.Echo "ERR usage: find-in-editor.vbs <STRING> [PROBE]" : WScript.Quit 2
needle = WScript.Arguments(0)
probe = False
If WScript.Arguments.Count > 1 Then probe = True

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If

sess.FindById("wnd[0]").SendVKey 71   ' Ctrl+F = Find
WScript.Sleep 1200

If sess.Children.Count < 2 Then
  WScript.Echo "ERR no find dialog appeared"
  WScript.Quit 3
End If

WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text

If probe Then
  Dump sess.FindById("wnd[1]"), 0
  WScript.Quit 0
End If

' Try the usual field ids for the find dialog
Dim ok, ids, k
ok = False
ids = Array("wnd[1]/usr/txtRSTXP-TDFIND", "wnd[1]/usr/txtRSTXP-STRING", "wnd[1]/usr/txtSTRING")
For k = 0 To UBound(ids)
  On Error Resume Next
  sess.FindById(ids(k)).Text = needle
  If Err.Number = 0 Then ok = True : Err.Clear : Exit For
  Err.Clear
  On Error GoTo 0
Next
On Error GoTo 0

If Not ok Then
  WScript.Echo "ERR could not set search field; run with PROBE to inspect"
  Dump sess.FindById("wnd[1]"), 0
  WScript.Quit 4
End If

sess.FindById("wnd[1]").SendVKey 0
WScript.Sleep 1200

' A 'not found' or 'wrap' popup may appear
If sess.Children.Count > 1 Then
  WScript.Echo "AFTER_MODAL=" & sess.FindById("wnd[1]").Text
End If

WScript.Echo "OK searched for " & needle
WScript.Echo "SBAR=" & sess.FindById("wnd[0]/sbar").Text

Sub Dump(node, depth)
  Dim j, kid
  On Error Resume Next
  WScript.Echo Space(depth * 2) & node.Id & " [" & node.Type & "] '" & Left(node.Text, 60) & "'"
  If node.ContainerType = True Then
    For j = 0 To node.Children.Count - 1
      Set kid = node.Children.Item(CLng(j))
      Dump kid, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub
