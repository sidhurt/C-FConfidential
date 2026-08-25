Option Explicit
' In the SE37 structure editor, scroll right N times and dump the visible
' field labels and input ids each time.  Usage: struct_scroll.vbs <times>
Dim sapGuiAuto, app, conn, sess, elapsed, n, i, k, ch, u, b, tip, rightBtn

n = CInt(WScript.Arguments(0))

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If

WScript.Echo "--- toolbar ---"
rightBtn = ""
For i = 0 To 50
  On Error Resume Next
  Set b = Nothing
  Set b = sess.FindById("wnd[0]/tbar[1]/btn[" & i & "]")
  If Err.Number = 0 And Not b Is Nothing Then
    tip = b.Tooltip
    WScript.Echo "  btn[" & i & "] '" & b.Text & "' tip='" & tip & "'"
    If InStr(tip, "Scroll Right") > 0 Then rightBtn = "wnd[0]/tbar[1]/btn[" & i & "]"
  End If
  Err.Clear
  On Error GoTo 0
Next

If rightBtn = "" Then WScript.Echo "NO_SCROLL_RIGHT" : WScript.Quit 11

For i = 1 To n
  sess.FindById(rightBtn).Press
  Ready 30000
  WScript.Echo "===== after scroll " & i & " ====="
  Set u = sess.FindById("wnd[0]/usr")
  For k = 0 To u.Children.Count - 1
    Set ch = u.Children.Item(CLng(k))
    On Error Resume Next
    Dim sid
    sid = ch.Id
    sid = Mid(sid, InStr(sid, "/usr/") + 5)
    If ch.Type = "GuiLabel" And InStr(sid, ",1]") > 0 Then
      WScript.Echo "  LBL " & sid & " = '" & ch.Text & "'"
    End If
    Err.Clear
    On Error GoTo 0
  Next
Next

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 600
End Sub
