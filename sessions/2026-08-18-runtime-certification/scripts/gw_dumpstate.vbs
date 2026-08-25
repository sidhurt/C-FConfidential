Option Explicit
Dim sapGuiAuto, app, conn, sess, sh, st, i, n
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
For n = 2 To 3
  WScript.Echo "===== PANE " & n & " ====="
  On Error Resume Next
  Set sh = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[" & n & "]/shell")
  Set st = sh.DumpState(0)
  If Err.Number <> 0 Then
    WScript.Echo "DumpState failed: " & Err.Description
    Err.Clear
  Else
    WScript.Echo "entries=" & st.Count
    For i = 0 To st.Count - 1
      Dim v : v = "" : v = st.ElementAt(CLng(i))
      Dim k : k = "" : k = st.ElementNameAt(CLng(i))
      If Len(v) > 300 Then v = Left(v, 300) & "...<" & Len(v) & " chars>"
      WScript.Echo "  " & k & " = " & v
    Next
  End If
  On Error GoTo 0
Next
