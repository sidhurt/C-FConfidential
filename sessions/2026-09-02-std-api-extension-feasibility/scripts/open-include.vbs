Option Explicit
' READ-ONLY. Opens a program/include in SE38 Display and optionally scrolls to a line.
' Never enters change mode, never edits, never saves.
' Usage: open-include.vbs <PROGNAME> [FIRSTVISIBLELINE]

Dim SapGuiAuto, app, conn, sess, prog, firstLine, editor, ids, i, title
If WScript.Arguments.Count < 1 Then WScript.Echo "ERR usage: open-include.vbs <PROG> [LINE]" : WScript.Quit 2
prog = WScript.Arguments(0)
firstLine = 0
If WScript.Arguments.Count > 1 Then firstLine = CLng(WScript.Arguments(1))

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine

Dim ci, si, s, found
found = False
For ci = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(ci))
  For si = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(si))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT no QS4/700 session" : WScript.Quit 9

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE38"
sess.FindById("wnd[0]").SendVKey 0
WScript.Sleep 1500

sess.FindById("wnd[0]/usr/ctxtRS38M-PROGRAMM").Text = prog
sess.FindById("wnd[0]/usr/radRS38M-FUNC_EDIT").Select
WScript.Sleep 300
sess.FindById("wnd[0]/mbar/menu[0]/menu[2]").Select   ' Program > Display
WScript.Sleep 2500

If sess.Children.Count > 1 Then
  WScript.Echo "ERR modal: " & sess.FindById("wnd[1]").Text
  WScript.Quit 3
End If

title = sess.FindById("wnd[0]").Text
WScript.Echo "TITLE=" & title

ids = Array( _
  "wnd[0]/usr/cntlEDITOR/shellcont/shell", _
  "wnd[0]/usr/subEDITORSUBSCREEN:SAPLEDITOR_START:8430/cntlEDITOR/shellcont/shell", _
  "wnd[0]/usr/subSUBSCREEN:SAPLSEDITOR:0100/cntlEDITOR/shellcont/shell" )
Set editor = Nothing
For i = 0 To UBound(ids)
  On Error Resume Next
  Set editor = sess.FindById(ids(i))
  If Err.Number = 0 And Not editor Is Nothing Then Err.Clear : Exit For
  Set editor = Nothing
  Err.Clear
Next
On Error GoTo 0

If editor Is Nothing Then
  WScript.Echo "WARN no editor control found (screen may still be usable)"
Else
  If firstLine > 0 Then
    On Error Resume Next
    editor.FirstVisibleLine = firstLine
    If Err.Number <> 0 Then WScript.Echo "WARN could not scroll: " & Err.Description
    Err.Clear
    On Error GoTo 0
    WScript.Sleep 600
  End If
End If

WScript.Echo "OK " & prog
