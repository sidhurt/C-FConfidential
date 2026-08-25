Option Explicit
' /IWFND/GW_CLIENT capture harness. READ-ONLY: only GET and HEAD are permitted by this script.
' Usage: cscript //nologo gw_capture.vbs <METHOD> <uri> <outDir> <baseName>
' Writes  <base>_request.txt, <base>_response_headers.tsv (cookies redacted), <base>_response.<ext>
Dim sapGuiAuto, app, conn, sess, elapsed
Dim method, uri, outDir, baseName, i, g, r, nm, vl, status, reason, ctype, ext, fso, f

Set fso = CreateObject("Scripting.FileSystemObject")
If WScript.Arguments.Count < 4 Then WScript.Echo "usage" : WScript.Quit 2
method  = UCase(WScript.Arguments(0))
uri     = WScript.Arguments(1)
outDir  = WScript.Arguments(2)
baseName= WScript.Arguments(3)

If method <> "GET" And method <> "HEAD" Then
  WScript.Echo "ERROR: this harness refuses method " & method & " (read-only by design)"
  WScript.Quit 8
End If

Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "ERROR: expected DS4/200, found " & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If

' close any stray modal
Do While sess.Children.Count > 1
  sess.FindById("wnd[" & (sess.Children.Count - 1) & "]").SendVKey 12
  Ready 8000
Loop

If sess.Info.Transaction <> "/IWFND/GW_CLIENT" Then
  sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n/IWFND/GW_CLIENT"
  sess.FindById("wnd[0]").SendVKey 0
  Ready 30000
End If

If method = "GET" Then
  sess.FindById("wnd[0]/usr/radRB_GET").Select
Else
  sess.FindById("wnd[0]/usr/radRB_HEAD").Select
End If
sess.FindById("wnd[0]/usr/cntlURI_AREA/shellcont/shell").Text = uri
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
Ready 180000

' ---- response headers ----
status = "" : reason = "" : ctype = ""
Set f = fso.CreateTextFile(fso.BuildPath(outDir, baseName & "_response_headers.tsv"), True)
f.WriteLine "NAME" & vbTab & "VALUE"
On Error Resume Next
Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[1]/shell")
If Err.Number = 0 Then
  For r = 0 To g.RowCount - 1
    nm = g.GetCellValue(CLng(r), "NAME")
    vl = g.GetCellValue(CLng(r), "VALUE")
    If nm = "~status_code" Then status = vl
    If nm = "~status_reason" Then reason = vl
    If nm = "content-type" Then ctype = vl
    If LCase(nm) = "set-cookie" Or LCase(nm) = "cookie" Or LCase(nm) = "x-csrf-token" Or LCase(nm) = "authorization" Then vl = "[REDACTED]"
    f.WriteLine nm & vbTab & vl
  Next
  f.WriteLine "~grid_title" & vbTab & g.Title
End If
Err.Clear
On Error GoTo 0
f.Close

' ---- request record ----
Set f = fso.CreateTextFile(fso.BuildPath(outDir, baseName & "_request.txt"), True)
f.WriteLine method & " " & uri & " HTTP/1.1"
f.WriteLine "X-System: " & sess.Info.SystemName
f.WriteLine "X-Client: " & sess.Info.Client
f.WriteLine "X-User: " & sess.Info.User
f.WriteLine "X-Executed-Via: /IWFND/GW_CLIENT (SAP GUI scripting, session reuse; no credentials handled)"
f.WriteLine "X-Captured-UTC: " & UTCStamp()
f.WriteLine "X-Status: " & status & " " & reason
f.Close

' ---- body download ----
ext = "txt"
If InStr(LCase(ctype), "xml") > 0 Then ext = "xml"
If InStr(LCase(ctype), "json") > 0 Then ext = "json"
If InStr(LCase(ctype), "html") > 0 Then ext = "html"

sess.FindById("wnd[0]/mbar/menu[0]/menu[0]").Select
Ready 20000
If sess.Children.Count > 1 And sess.FindById("wnd[1]").Text = "Save File" Then
  sess.FindById("wnd[1]/usr/ctxtDY_PATH").Text = outDir & "\"
  sess.FindById("wnd[1]/usr/ctxtDY_FILENAME").Text = baseName & "_response." & ext
  sess.FindById("wnd[1]/tbar[0]/btn[11]").Press   ' Replace
  Ready 60000
Else
  WScript.Echo "WARN: Save File dialog did not appear; body not downloaded"
End If
Do While sess.Children.Count > 1
  sess.FindById("wnd[" & (sess.Children.Count - 1) & "]").SendVKey 12
  Ready 8000
Loop

WScript.Echo "OK|METHOD=" & method & "|STATUS=" & status & " " & reason & "|CTYPE=" & ctype & "|BODY=" & baseName & "_response." & ext
WScript.Echo "URI=" & uri

Function UTCStamp()
  Dim d : Set d = CreateObject("WbemScripting.SWbemDateTime")
  d.SetVarDate Now, True
  UTCStamp = d.GetVarDate(False)
End Function
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
