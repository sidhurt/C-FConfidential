Option Explicit
' READ-ONLY QS4/700 /IWFND/GW_CLIENT: execute GET/HEAD and read panes in-place.
' No file download. Usage: qs4_gw_exec_read.vbs <METHOD> <URI> [DUMPMENU]
Dim sapGuiAuto, app, conn, s, sess, found, elapsed, i, j
Dim method, uri, g, r, nm, vl, status, reason, ctype, clen, base, sh, t, optDump

If WScript.Arguments.Count < 2 Then WScript.Echo "USAGE|METHOD URI" : WScript.Quit 2
method = UCase(WScript.Arguments(0))
uri    = WScript.Arguments(1)
optDump = (WScript.Arguments.Count > 2)

If method <> "GET" And method <> "HEAD" Then WScript.Echo "REFUSED|READ_ONLY|" & method : WScript.Quit 8

Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_QS4_700_SESSION" : WScript.Quit 9
WScript.Echo "SESSION|QS4/700|USER=" & sess.Info.User

CloseModals

If sess.Info.Transaction <> "/IWFND/GW_CLIENT" Then
  sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n/IWFND/GW_CLIENT"
  sess.FindById("wnd[0]").SendVKey 0
  Ready 40000
End If
CloseModals

If optDump Then
  WScript.Echo "--- menus ---"
  DumpMenu
  WScript.Echo "--- usr tree ---"
  Walk sess.FindById("wnd[0]/usr"), 0
End If

If method = "GET" Then
  sess.FindById("wnd[0]/usr/radRB_GET").Select
Else
  sess.FindById("wnd[0]/usr/radRB_HEAD").Select
End If
sess.FindById("wnd[0]/usr/cntlURI_AREA/shellcont/shell").Text = uri
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
Ready 300000
CloseModals

status = "" : reason = "" : ctype = "" : clen = ""
On Error Resume Next
Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[1]/shell")
If Err.Number = 0 Then
  For r = 0 To g.RowCount - 1
    nm = g.GetCellValue(CLng(r), "NAME")
    vl = g.GetCellValue(CLng(r), "VALUE")
    Select Case nm
      Case "~status_code"   : status = vl
      Case "~status_reason" : reason = vl
      Case "content-type"   : ctype = vl
      Case "content-length" : clen = vl
    End Select
  Next
End If
Err.Clear
On Error GoTo 0

WScript.Echo "STATUS|" & status & " " & reason & "|CTYPE=" & ctype & "|CLEN=" & clen
WScript.Echo "URI|" & uri

base = "wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont["
For i = 0 To 5
  On Error Resume Next
  Set sh = Nothing
  Set sh = sess.FindById(base & i & "]/shell")
  If Err.Number = 0 And Not sh Is Nothing Then
    t = "" : t = sh.Text
    WScript.Echo "PANE[" & i & "]|SubType=" & sh.SubType & "|TextLen=" & Len(t)
  End If
  Err.Clear
  On Error GoTo 0
Next

Sub DumpMenu()
  Dim a, b, m1, m2
  On Error Resume Next
  For a = 0 To 6
    Set m1 = Nothing
    Set m1 = sess.FindById("wnd[0]/mbar/menu[" & a & "]")
    If Err.Number = 0 And Not m1 Is Nothing Then
      WScript.Echo "menu[" & a & "] = " & m1.Text
      For b = 0 To 20
        Set m2 = Nothing
        Set m2 = sess.FindById("wnd[0]/mbar/menu[" & a & "]/menu[" & b & "]")
        If Err.Number = 0 And Not m2 Is Nothing Then WScript.Echo "   menu[" & a & "]/menu[" & b & "] = " & m2.Text
        Err.Clear
      Next
    End If
    Err.Clear
  Next
  On Error GoTo 0
End Sub

Sub Walk(node, depth)
  Dim k, child, ty, tx
  If depth > 6 Then Exit Sub
  On Error Resume Next
  ty = node.Type : tx = ""
  If ty = "GuiLabel" Or ty = "GuiButton" Or ty = "GuiRadioButton" Or ty = "GuiCheckBox" Then tx = node.Text
  WScript.Echo Space(depth*2) & "[" & ty & "/" & node.SubType & "] " & Replace(node.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & " " & tx
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Walk child, depth + 1
    Next
  End If
  On Error GoTo 0
End Sub

Sub CloseModals()
  Dim guard : guard = 0
  Do While sess.Children.Count > 1 And guard < 8
    sess.FindById("wnd[" & (sess.Children.Count - 1) & "]").SendVKey 12
    Ready 10000
    guard = guard + 1
  Loop
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
