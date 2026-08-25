Option Explicit
' /IWFND/GW_CLIENT READ-ONLY capture harness (GET/HEAD only, enforced).
' Usage: cscript //nologo gw_get.vbs <METHOD> <uri> <outDir> <baseName>
Dim sapGuiAuto, app, conn, sess, elapsed, fso, f
Dim method, uri, outDir, baseName, g, r, nm, vl, status, reason, ctype, clen

Set fso = CreateObject("Scripting.FileSystemObject")
If WScript.Arguments.Count < 4 Then WScript.Echo "usage: gw_get.vbs METHOD URI OUTDIR BASENAME" : WScript.Quit 2
method   = UCase(WScript.Arguments(0))
uri      = WScript.Arguments(1)
outDir   = WScript.Arguments(2)
baseName = WScript.Arguments(3)

If method <> "GET" And method <> "HEAD" Then
  WScript.Echo "REFUSED: harness is read-only; method " & method & " not permitted"
  WScript.Quit 8
End If

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED: expected DS4/200, session is " & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If

CloseModals

If sess.Info.Transaction <> "/IWFND/GW_CLIENT" Then
  sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n/IWFND/GW_CLIENT"
  sess.FindById("wnd[0]").SendVKey 0
  Ready 30000
End If

' reset the screen so no stale request body survives from a previous capture
sess.FindById("wnd[0]/mbar/menu[1]/menu[2]").Select
Ready 20000
CloseModals

If method = "GET" Then
  sess.FindById("wnd[0]/usr/radRB_GET").Select
Else
  sess.FindById("wnd[0]/usr/radRB_HEAD").Select
End If
sess.FindById("wnd[0]/usr/cntlURI_AREA/shellcont/shell").Text = uri
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
Ready 300000
CloseModals

' ---------- response headers ----------
status = "" : reason = "" : ctype = "" : clen = ""
Set f = fso.CreateTextFile(fso.BuildPath(outDir, baseName & "_response_headers.tsv"), True)
f.WriteLine "NAME" & vbTab & "VALUE"
On Error Resume Next
Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[1]/shell")
If Err.Number = 0 Then
  For r = 0 To g.RowCount - 1
    nm = g.GetCellValue(CLng(r), "NAME")
    vl = g.GetCellValue(CLng(r), "VALUE")
    Select Case nm
      Case "~status_code"   : status = vl
      Case "~status_reason" : reason = vl
      Case "content-type"   : ctype  = vl
      Case "content-length" : clen   = vl
    End Select
    Select Case LCase(nm)
      Case "set-cookie", "cookie", "x-csrf-token", "authorization" : vl = "[REDACTED]"
    End Select
    f.WriteLine nm & vbTab & vl
  Next
  f.WriteLine "~grid_title" & vbTab & g.Title
End If
Err.Clear
On Error GoTo 0
f.Close

' ---------- request record ----------
Set f = fso.CreateTextFile(fso.BuildPath(outDir, baseName & "_request.txt"), True)
f.WriteLine method & " " & uri & " HTTP/1.1"
f.WriteLine "Host: (DS4 application server, resolved by /IWFND/GW_CLIENT)"
f.WriteLine "Accept: */*"
f.WriteLine ""
f.WriteLine "# executed in " & sess.Info.SystemName & " client " & sess.Info.Client & " as " & sess.Info.User
f.WriteLine "# transport: /IWFND/GW_CLIENT via SAP GUI scripting on the operator's existing session"
f.WriteLine "# no credentials, cookies or CSRF tokens were handled or stored by this harness"
f.WriteLine "# captured (local): " & Now
f.WriteLine "# result: HTTP " & status & " " & reason & " | content-type " & ctype & " | content-length " & clen
f.Close

' ---------- body: copy response into request editor, then export the test case ----------
On Error Resume Next
g.PressToolbarButton "COPY_BODY"
Ready 60000
On Error GoTo 0
CloseModals


WScript.Echo "OK|STATUS=" & status & " " & reason & "|CTYPE=" & ctype & "|CLEN=" & clen & "|BODY=response copied into request editor for clipboard capture"

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
  WScript.Sleep 800
End Sub
