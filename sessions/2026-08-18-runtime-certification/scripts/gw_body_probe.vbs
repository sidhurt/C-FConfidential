Option Explicit
Dim sapGuiAuto, app, conn, sess, sh, bh, doc, t
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

WScript.Echo "--- tbar[1] tooltips ---"
Dim ids, k
ids = Array("8","25","9","26","19","20")
For k = 0 To UBound(ids)
  On Error Resume Next
  WScript.Echo "btn[" & ids(k) & "] Text='" & sess.FindById("wnd[0]/tbar[1]/btn[" & ids(k) & "]").Text & "' Tip='" & sess.FindById("wnd[0]/tbar[1]/btn[" & ids(k) & "]").Tooltip & "'"
  Err.Clear
  On Error GoTo 0
Next

WScript.Echo "--- HTMLViewer BrowserHandle ---"
On Error Resume Next
Set sh = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[3]/shell")
WScript.Echo "shell subtype=" & sh.SubType
Set bh = sh.BrowserHandle
If Err.Number <> 0 Then
  WScript.Echo "BrowserHandle FAILED: " & Err.Description
  Err.Clear
Else
  WScript.Echo "BrowserHandle OK. LocationURL=" & bh.LocationURL
  Set doc = bh.Document
  If Err.Number <> 0 Then
    WScript.Echo "Document FAILED: " & Err.Description
    Err.Clear
  Else
    t = doc.documentElement.outerHTML
    WScript.Echo "outerHTML len=" & Len(t)
    WScript.Echo "FIRST400=" & Left(Replace(Replace(t, vbCr, " "), vbLf, " "), 400)
    t = doc.body.innerText
    WScript.Echo "innerText len=" & Len(t)
    WScript.Echo "TXT400=" & Left(Replace(Replace(t, vbCr, " "), vbLf, " "), 400)
  End If
End If
On Error GoTo 0

WScript.Echo "--- AbapEditor pane[2] ---"
On Error Resume Next
Dim ed
Set ed = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[2]/shell")
WScript.Echo "pane2 subtype=" & ed.SubType & " lines=" & ed.LinesCount
WScript.Echo "pane2 getText err=" & Err.Description
Err.Clear
On Error GoTo 0
