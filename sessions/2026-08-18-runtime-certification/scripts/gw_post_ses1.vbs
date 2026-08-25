Option Explicit
' /IWFND/GW_CLIENT POST driven in DS4/200 SESSION 1 ONLY, so it never disturbs
' whatever is running in session 0.  Loads a local JSON payload as the request
' body, executes, then dumps the response header grid AND every shell in the
' user area so the response body pane can be located and read.
' Usage: gw_post_ses1.vbs <uri> <dir> <filename> <outPrefix>
Dim sapGuiAuto, app, conn, sess, elapsed, uri, dir, fn, outPre
Dim i, j, s, found, g, r, c, nm, vl, fso, f

uri    = WScript.Arguments(0)
dir    = WScript.Arguments(1)
fn     = WScript.Arguments(2)
outPre = WScript.Arguments(3)
Dim bodyDir, bodyFile
bodyDir  = WScript.Arguments(4)
bodyFile = WScript.Arguments(5)

Set fso = CreateObject("Scripting.FileSystemObject")
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine

found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" And j = 1 Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_SESSION_1" : WScript.Quit 9
WScript.Echo "SESSION|" & sess.Id & "|user=" & sess.Info.User

If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n/IWFND/GW_CLIENT"
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text

sess.FindById("wnd[0]/usr/radRB_POST").Select
sess.FindById("wnd[0]/usr/cntlURI_AREA/shellcont/shell").Text = uri
Ready 10000
WScript.Echo "METHOD|POST|URI|" & uri

' attach the request body from file
Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[0]/shell")
g.PressToolbarButton "ADD_FILE"
Ready 60000
If sess.Children.Count < 2 Then WScript.Echo "ABORT|NO_FILE_DIALOG" : WScript.Quit 11
WScript.Echo "DIALOG|" & sess.FindById("wnd[1]").Text
sess.FindById("wnd[1]/usr/ctxtDY_PATH").Text = dir
sess.FindById("wnd[1]/usr/ctxtDY_FILENAME").Text = fn
sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
Ready 60000
WScript.Echo "BODY_LOADED|" & dir & fn & "|windows=" & sess.Children.Count

' execute
sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
Ready 300000
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_EXEC|" & sess.FindById("wnd[1]").Text
End If
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text

' response headers
On Error Resume Next
Set g = Nothing
Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[1]/shell")
If Err.Number = 0 And Not g Is Nothing Then
  Set f = fso.CreateTextFile(outPre & "_headers.tsv", True)
  f.WriteLine "NAME" & vbTab & "VALUE"
  For r = 0 To g.RowCount - 1
    nm = g.GetCellValue(CLng(r), "NAME")
    vl = g.GetCellValue(CLng(r), "VALUE")
    Select Case LCase(nm)
      Case "set-cookie", "cookie", "x-csrf-token", "authorization" : vl = "[REDACTED]"
    End Select
    f.WriteLine nm & vbTab & vl
    If nm = "~status_code" Or nm = "~status_reason" Or nm = "content-length" Then WScript.Echo "  " & nm & " = " & vl
  Next
  f.Close
End If
Err.Clear
On Error GoTo 0

' ---- body download via Response -> Save menu ----
On Error Resume Next
sess.FindById("wnd[0]/mbar/menu[0]/menu[0]").Select
Ready 20000
If sess.Children.Count > 1 And sess.FindById("wnd[1]").Text = "Save File" Then
  sess.FindById("wnd[1]/usr/ctxtDY_PATH").Text = bodyDir
  sess.FindById("wnd[1]/usr/ctxtDY_FILENAME").Text = bodyFile
  sess.FindById("wnd[1]/tbar[0]/btn[11]").Press
  Ready 60000
  WScript.Echo "BODY_DOWNLOADED|" & bodyDir & bodyFile
Else
  WScript.Echo "WARN|NO_SAVE_DIALOG|windows=" & sess.Children.Count
  If sess.Children.Count > 1 Then WScript.Echo "WARN|MODAL=" & sess.FindById("wnd[1]").Text
End If
Do While sess.Children.Count > 1
  sess.FindById("wnd[" & (sess.Children.Count - 1) & "]").SendVKey 12
  Ready 8000
Loop
Err.Clear
On Error GoTo 0

' hunt for the body pane

WScript.Echo "--- SHELL SCAN ---"
Walk sess.FindById("wnd[0]/usr"), 0, outPre

Sub Walk(node, depth, pre)
  Dim k, child, t, sub_, txt, fh2
  On Error Resume Next
  t = node.Type
  If t = "GuiShell" Then
    sub_ = node.SubType
    txt = ""
    txt = node.Text
    WScript.Echo "SHELL|" & node.Id & "|SubType=" & sub_ & "|len=" & Len(txt)
    If Len(txt) > 40 Then
      Set fh2 = fso.CreateTextFile(pre & "_body.txt", True)
      fh2.Write txt
      fh2.Close
      WScript.Echo "BODY_SAVED|" & pre & "_body.txt"
    End If
  End If
  If node.ContainerType = True And depth < 8 Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Walk child, depth + 1, pre
    Next
  End If
  On Error GoTo 0
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 1200
End Sub
