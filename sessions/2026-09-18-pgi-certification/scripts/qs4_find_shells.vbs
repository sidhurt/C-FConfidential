Option Explicit
' READ-ONLY. Lists every GuiShell under wnd[0] of the QS4/700 session (id, subtype).
' Touches nothing; used only to locate the editor control on an unfamiliar screen.
Dim app, conn, s, sess, ci, si, found
Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For ci = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(ci))
  For si = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(si))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT no QS4/700 session" : WScript.Quit 9
WScript.Echo "SCREEN|" & sess.Info.Program & "/" & sess.Info.ScreenNumber & "|" & sess.FindById("wnd[0]").Text
Walk sess.FindById("wnd[0]"), 0
Sub Walk(n, d)
  Dim k
  If d > 14 Then Exit Sub
  On Error Resume Next
  If n.Type = "GuiShell" Then WScript.Echo "SHELL|" & n.SubType & "|" & n.Id
  If n.ContainerType Then
    For k = 0 To n.Children.Count - 1
      Walk n.Children.Item(CLng(k)), d + 1
    Next
  End If
  On Error GoTo 0
End Sub
