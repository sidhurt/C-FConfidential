Option Explicit
' READ-ONLY: open SE16 for a table in QS4/700 and dump the selection-screen
' control ids alongside their on-screen labels. Never executes the query.
' Usage: cscript //nologo qs4_se16_selscreen.vbs <TABLE>
Dim sapGuiAuto, app, sess, elapsed, tbl, i, j, conn, s, found, u, k, ch, sid

tbl = UCase(WScript.Arguments(0))
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

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
Accept
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
Accept

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
Set u = sess.FindById("wnd[0]/usr")
Walk u, 0

Sub Walk(node, depth)
  Dim n, c2, id2
  On Error Resume Next
  If node.ContainerType = True Then
    For n = 0 To node.Children.Count - 1
      Set c2 = node.Children.Item(CLng(n))
      Walk c2, depth + 1
    Next
  Else
    id2 = node.Id
    id2 = Mid(id2, InStr(id2, "/usr/") + 5)
    WScript.Echo "NODE|" & node.Type & "|" & id2 & "|" & node.Text
  End If
  Err.Clear
  On Error GoTo 0
End Sub

Sub Accept()
  On Error Resume Next
  If sess.Children.Count > 1 Then
    If sess.FindById("wnd[1]").Text = "Select Fields for Selection" Then
      sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
      Ready 30000
    End If
  End If
  Err.Clear
  On Error GoTo 0
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 900
End Sub
