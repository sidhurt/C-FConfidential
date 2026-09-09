Option Explicit
' Scrolls the SE37 single-entry modal vertically and dumps the visible field rows.
' Usage: se37-modal-scroll.vbs <VPOS> [FILTER]
' Read-only; does not execute anything.

Dim SapGuiAuto, app, conn, sess, vpos, filt, r, lab, val

If WScript.Arguments.Count < 1 Then WScript.Echo "ERR usage: <VPOS> [FILTER]" : WScript.Quit 2
vpos = CLng(WScript.Arguments(0))
filt = ""
If WScript.Arguments.Count > 1 Then filt = UCase(WScript.Arguments(1))

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Children.Count < 2 Then WScript.Echo "ABORT no modal" : WScript.Quit 10

On Error Resume Next
sess.FindById("wnd[1]/usr").VerticalScrollbar.Position = vpos
If Err.Number <> 0 Then WScript.Echo "ERR scroll: " & Err.Description : Err.Clear
On Error GoTo 0
WScript.Sleep 1000

On Error Resume Next
WScript.Echo "VPOS=" & sess.FindById("wnd[1]/usr").VerticalScrollbar.Position & _
             " MAX=" & sess.FindById("wnd[1]/usr").VerticalScrollbar.Maximum
Err.Clear
On Error GoTo 0

For r = 0 To 40
  lab = "" : val = ""
  On Error Resume Next
  Err.Clear
  lab = sess.FindById("wnd[1]/usr/lbl[12," & r & "]").Text
  If Err.Number = 0 And Len(Trim(lab)) > 0 Then
    Err.Clear
    val = sess.FindById("wnd[1]/usr/txt[43," & r & "]").Text
    If filt = "" Or InStr(UCase(lab), filt) > 0 Then
      WScript.Echo "row " & r & "  " & lab & " = '" & Trim(val) & "'"
    End If
  End If
  Err.Clear
  On Error GoTo 0
Next
