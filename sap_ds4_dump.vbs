Option Explicit
Dim rot, sapGui, app, conn, sess, w0, root
Dim i, j, found
found = False
Set rot = CreateObject("SapROTWr.SapROTWrapper")
Set sapGui = rot.GetROTEntry("SAPGUI")
If sapGui Is Nothing Then WScript.Echo "STOP|no ROT" : WScript.Quit 2
Set app = sapGui.GetScriptingEngine
For i = 0 To app.Children.Count - 1
  Set conn = app.Children.Item(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set sess = conn.Children.Item(CLng(j))
    If sess.Info.SystemName = "DS4" And sess.Info.Client = "200" Then
      found = True
      Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "STOP|DS4/200 not found" : WScript.Quit 3
WScript.Echo "CONFIRM|" & sess.Info.SystemName & "|" & sess.Info.Client & "|" & sess.Info.Transaction & "|" & sess.Id
WScript.Echo "WINDOWS=" & sess.Children.Count
If sess.Children.Count <> 1 Then WScript.Echo "STOP|modal" : WScript.Quit 4
Set w0 = sess.FindById("wnd[0]")
WScript.Echo "ROOT|" & w0.Text
Set root = sess.FindById("wnd[0]/usr")
Dump root, 0
Sub Dump(o, depth)
  Dim k, child, pad, t, tx
  pad = String(depth * 2, " ")
  On Error Resume Next
  t = o.Type
  tx = o.Text
  WScript.Echo "NODE|" & pad & o.Id & "|" & t & "|" & o.Name & "|" & tx
  For k = 0 To o.Children.Count - 1
    Set child = o.Children.Item(CLng(k))
    If Err.Number = 0 Then Dump child, depth + 1
    Err.Clear
  Next
  On Error GoTo 0
End Sub
