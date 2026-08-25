Option Explicit
Dim sapGuiAuto, app, conn, sess, sh, fso, ts, outf, t
outf = WScript.Arguments(0)
Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
Set sh = sess.FindById("wnd[0]/usr/tabsFUNC_TAB_STRIP/tabpSOURCE/ssubSCREEN_HEADER:SAPLEDITOR_START:8430/cntlEDITOR/shellcont/shell")
WScript.Echo "TYPE|" & sh.Type & "|SUBTYPE|" & sh.SubType
On Error Resume Next
t = sh.Text
If Err.Number <> 0 Then WScript.Echo "ERR_TEXT|" & Err.Description : Err.Clear
On Error GoTo 0
If Len(t) = 0 Then WScript.Echo "EMPTY_TEXT" : WScript.Quit 2
Set fso = CreateObject("Scripting.FileSystemObject")
Set ts  = fso.CreateTextFile(outf, True, True)
ts.Write t
ts.Close
WScript.Echo "OK|chars=" & Len(t) & "|" & outf
