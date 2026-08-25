Option Explicit
' In the SE37 structure editor, scroll right until a named label appears,
' then report its column so it can be filled.
' Usage: ds4_struct_find.vbs <LABELTEXT> [maxScrolls]
Dim app, sess, i, j, conn, s, found, elapsed, target, maxs, u, k, ch, n, hit
target = UCase(WScript.Arguments(0))
maxs = 12
If WScript.Arguments.Count > 1 Then maxs = CInt(WScript.Arguments(1))

Set app = GetObject("SAPGUI").GetScriptingEngine
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

For n = 0 To maxs
  Set u = sess.FindById("wnd[0]/usr")
  hit = ""
  For k = 0 To u.Children.Count - 1
    Set ch = u.Children.Item(CLng(k))
    On Error Resume Next
    If ch.Type = "GuiLabel" Then
      If InStr(UCase(ch.Text), target) = 1 Then hit = ch.Id
    End If
    Err.Clear
    On Error GoTo 0
  Next
  If hit <> "" Then
    WScript.Echo "FOUND|scroll=" & n & "|" & Mid(hit, InStr(hit, "/usr/") + 5)
    ' dump the value-row ids on this view
    For k = 0 To u.Children.Count - 1
      Set ch = u.Children.Item(CLng(k))
      On Error Resume Next
      If ch.Type = "GuiTextField" Or ch.Type = "GuiCTextField" Then
        WScript.Echo "  FIELD " & Mid(ch.Id, InStr(ch.Id, "/usr/") + 5) & " = '" & ch.Text & "'"
      End If
      Err.Clear
      On Error GoTo 0
    Next
    WScript.Quit 0
  End If
  sess.FindById("wnd[0]/tbar[1]/btn[47]").Press
  Ready 20000
Next
WScript.Echo "NOT_FOUND after " & maxs & " scrolls"

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 400
End Sub
