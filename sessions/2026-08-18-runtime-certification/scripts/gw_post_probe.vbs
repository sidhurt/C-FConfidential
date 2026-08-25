Option Explicit
' /IWFND/GW_CLIENT: set method POST + URI, then press "Add File" on the request
' grid and dump whatever dialog appears, so the file-load path can be identified.
' Nothing is executed - this stops before Execute.
Dim sapGuiAuto, app, conn, sess, elapsed, uri, g, i, b, k, ch, u

uri = WScript.Arguments(0)

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n/IWFND/GW_CLIENT"
sess.FindById("wnd[0]").SendVKey 0
Ready 60000

sess.FindById("wnd[0]/usr/radRB_POST").Select
sess.FindById("wnd[0]/usr/cntlURI_AREA/shellcont/shell").Text = uri
Ready 10000
WScript.Echo "METHOD|POST"
WScript.Echo "URI|" & uri

Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[0]/shell")
WScript.Echo "GRID|" & g.Title
For i = 0 To g.ToolbarButtonCount - 1
  WScript.Echo "  btn " & i & " id='" & g.GetToolbarButtonId(CLng(i)) & "' text='" & g.GetToolbarButtonText(CLng(i)) & "' enabled=" & g.GetToolbarButtonEnabled(CLng(i))
Next

g.PressToolbarButton "ADD_FILE"
Ready 60000

WScript.Echo "WINDOWS|" & sess.Children.Count
For i = 1 To sess.Children.Count - 1
  WScript.Echo "--- wnd[" & i & "] '" & sess.Children.Item(CLng(i)).Text & "'"
  On Error Resume Next
  Set u = sess.FindById("wnd[" & i & "]/usr")
  For k = 0 To u.Children.Count - 1
    Set ch = u.Children.Item(CLng(k))
    WScript.Echo "    [" & ch.Type & "] " & Mid(ch.Id, InStr(ch.Id, "/usr/") + 5) & " = '" & ch.Text & "'"
  Next
  Err.Clear
  For k = 0 To 20
    Set b = Nothing
    Set b = sess.FindById("wnd[" & i & "]/tbar[0]/btn[" & k & "]")
    If Err.Number = 0 And Not b Is Nothing Then
      WScript.Echo "    [btn] tbar[0]/btn[" & k & "] '" & b.Text & "' tip='" & b.Tooltip & "'"
    End If
    Err.Clear
  Next
  On Error GoTo 0
Next

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
