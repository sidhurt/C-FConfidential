Option Explicit
' Close ONLY the "Choose Field for Positioning" dialog that we opened ourselves.
Dim app, sess, i, j, conn, s, found
Set app = GetObject("SAPGUI").GetScriptingEngine
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
If Not found Then WScript.Echo "ABORT|NO_DS4_200" : WScript.Quit 9
If sess.Children.Count < 2 Then WScript.Echo "NO_MODAL" : WScript.Quit 0
If sess.FindById("wnd[1]").Text <> "Choose Field for Positioning" Then
  WScript.Echo "REFUSED|unexpected modal: " & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If
sess.FindById("wnd[1]").Close
WScript.Sleep 800
WScript.Echo "CLOSED|windows now=" & sess.Children.Count & "|" & sess.FindById("wnd[0]").Text
