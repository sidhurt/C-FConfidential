Option Explicit
' Scrolls the current screen's user area horizontally and dumps visible labels/fields.
' Usage: se37-scroll-dump.vbs <HPOS>
' DOES NOT EXECUTE ANY FUNCTION MODULE.

Dim SapGuiAuto, app, conn, sess, hpos

If WScript.Arguments.Count < 1 Then WScript.Echo "ERR usage: <HPOS>" : WScript.Quit 2
hpos = CLng(WScript.Arguments(0))

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If

On Error Resume Next
sess.FindById("wnd[0]/usr").HorizontalScrollbar.Position = hpos
If Err.Number <> 0 Then
  WScript.Echo "ERR scroll: " & Err.Description
  Err.Clear
End If
On Error GoTo 0
WScript.Sleep 1200

WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text
On Error Resume Next
WScript.Echo "HPOS=" & sess.FindById("wnd[0]/usr").HorizontalScrollbar.Position & _
             " MAX=" & sess.FindById("wnd[0]/usr").HorizontalScrollbar.Maximum
Err.Clear
On Error GoTo 0

Dump sess.FindById("wnd[0]/usr"), 0

Sub Dump(node, depth)
  Dim k, kid, t, nm
  On Error Resume Next
  t = node.Type : nm = node.Text
  If t = "GuiLabel" Or t = "GuiTextField" Or t = "GuiCTextField" Then
    WScript.Echo node.Id & " [" & t & "] '" & Left(nm, 30) & "'"
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set kid = node.Children.Item(CLng(k))
      Dump kid, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub
