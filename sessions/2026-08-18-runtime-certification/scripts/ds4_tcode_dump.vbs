Option Explicit
' READ-ONLY: open a transaction in DS4/200 and dump the screen contents.
' Usage: cscript //nologo ds4_tcode_dump.vbs <TCODE>
Dim sapGuiAuto, app, sess, elapsed, tc, i, j, conn, s, found, u

tc = WScript.Arguments(0)
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_200_SESSION" : WScript.Quit 9

WScript.Echo "SESSIONINFO|host=" & sess.Info.ApplicationServer & "|sysno=" & sess.Info.SystemNumber & "|sysname=" & sess.Info.SystemName & "|client=" & sess.Info.Client

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/n" & tc
sess.FindById("wnd[0]").SendVKey 0
Ready 60000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "TCODE|" & sess.Info.Transaction
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text
Walk sess.FindById("wnd[0]/usr"), 0

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
    If Len(Trim(node.Text)) > 0 Then
      WScript.Echo "  [" & node.Type & "] " & id2 & " = " & node.Text
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
