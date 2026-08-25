Option Explicit
' Execute the request currently loaded in /IWFND/GW_CLIENT and capture the
' response header grid (cookies and tokens redacted).  Usage: gw_execute.vbs <outFile>
Dim sapGuiAuto, app, conn, sess, elapsed, outFile, fso, f, g, r, nm, vl, i

outFile = WScript.Arguments(0)
Set fso = CreateObject("Scripting.FileSystemObject")

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

WScript.Echo "EXECUTING|" & sess.FindById("wnd[0]/usr/cntlURI_AREA/shellcont/shell").Text
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
Ready 300000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_EXEC|" & sess.FindById("wnd[1]").Text & "|left open"
  WScript.Quit 13
End If

Set f = fso.CreateTextFile(outFile, True)
f.WriteLine "NAME" & vbTab & "VALUE"
On Error Resume Next
Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[1]/shell")
If Err.Number = 0 Then
  WScript.Echo "GRID|" & g.Title
  For r = 0 To g.RowCount - 1
    nm = g.GetCellValue(CLng(r), "NAME")
    vl = g.GetCellValue(CLng(r), "VALUE")
    Select Case LCase(nm)
      Case "set-cookie", "cookie", "x-csrf-token", "authorization" : vl = "[REDACTED]"
    End Select
    f.WriteLine nm & vbTab & vl
    If nm = "~status_code" Or nm = "~status_reason" Or nm = "content-length" Or nm = "content-type" Then
      WScript.Echo "  " & nm & " = " & vl
    End If
  Next
End If
Err.Clear
On Error GoTo 0
f.Close
WScript.Echo "SAVED|" & outFile

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 1200
End Sub
