Option Explicit
' Fills fields on the topmost window of a named system/client, optionally
' presses a key, then dumps the resulting screen.
' USAGE: sap-fill.vbs <SYS> <CLIENT> <VKEY|NONE> <fieldid>=<value> ...
'   fieldid is relative to the topmost window's /usr, e.g. txtG_ENHSTRU-ENHNAME
'   VKEY 0 = Enter, 3 = Back, 11 = Save, 8 = Execute, NONE = fill only
Dim app, conn, s, sess, found, i, j, wantSys, wantCli, vkey, elapsed, top, arg, p, fid, val

If WScript.Arguments.Count < 4 Then WScript.Echo "USAGE|SYS CLIENT VKEY f=v ..." : WScript.Quit 1
wantSys = UCase(CStr(WScript.Arguments(0)))
wantCli = CStr(WScript.Arguments(1))
vkey    = UCase(CStr(WScript.Arguments(2)))

Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = wantSys And s.Info.Client = wantCli Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NOT_FOUND" : WScript.Quit 9

top = "wnd[" & (sess.Children.Count - 1) & "]"
WScript.Echo "TOP=" & top & " '" & sess.FindById(top).Text & "'"

For i = 3 To WScript.Arguments.Count - 1
  arg = CStr(WScript.Arguments(i))
  p = InStr(arg, "=")
  If p > 1 Then
    fid = Left(arg, p - 1)
    val = Mid(arg, p + 1)
    On Error Resume Next
    Err.Clear
    sess.FindById(top & "/usr/" & fid).Text = val
    If Err.Number <> 0 Then
      WScript.Echo "FAIL|" & fid & "|" & Err.Description
      Err.Clear
    Else
      WScript.Echo "SET|" & fid & "=" & val
    End If
    On Error GoTo 0
  End If
Next

If vkey <> "NONE" Then
  WScript.Sleep 400
  sess.FindById(top).SendVKey CLng(vkey)
  Ready 30000
End If

WScript.Echo "----"
WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR=" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "WINDOWS=" & sess.Children.Count
Dim newtop
newtop = "wnd[" & (sess.Children.Count - 1) & "]"
WScript.Echo "NEWTOP=" & newtop & " '" & sess.FindById(newtop).Text & "'"
Dump sess.FindById(newtop & "/usr"), 0

Sub Dump(node, depth)
  Dim k, kid, t, nm, sid
  On Error Resume Next
  t = node.Type : nm = node.Text : sid = node.Id
  If InStr(sid, "/usr") > 0 Then sid = Mid(sid, InStr(sid, "/usr") + 4)
  If t <> "GuiLabel" Or Len(Trim(nm)) > 0 Then
    WScript.Echo Space(depth) & sid & " [" & t & "] '" & Left(nm, 50) & "'"
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set kid = node.Children.Item(CLng(k))
      Dump kid, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub

Sub Ready(maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
