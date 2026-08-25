Option Explicit
' SE37 structure editor: press Column/Position (btn[44]), type a field name,
' confirm, then dump the visible fields. Usage: ds4_struct_pos.vbs <FIELDNAME>
Dim app, sess, i, j, conn, s, found, elapsed, fld, u, k, ch, w
fld = UCase(WScript.Arguments(0))
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

sess.FindById("wnd[0]/tbar[1]/btn[44]").Press
Ready 30000
If sess.Children.Count < 2 Then WScript.Echo "NO_DIALOG" : WScript.Quit 10
WScript.Echo "DIALOG|" & sess.FindById("wnd[1]").Text
' find the input field in the modal
Set w = sess.FindById("wnd[1]/usr")
For k = 0 To w.Children.Count - 1
  Set ch = w.Children.Item(CLng(k))
  On Error Resume Next
  If ch.Type = "GuiTextField" Or ch.Type = "GuiCTextField" Then
    ch.Text = fld
    WScript.Echo "  set " & Mid(ch.Id, InStr(ch.Id, "/usr/") + 5) & " = " & fld
  End If
  Err.Clear
  On Error GoTo 0
Next
sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
Ready 30000

WScript.Echo "AFTER|" & sess.FindById("wnd[0]").Text
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If ch.Type = "GuiLabel" Then
    If Len(Trim(ch.Text)) > 0 Then WScript.Echo "  LBL " & Mid(ch.Id, InStr(ch.Id,"/usr/")+5) & " = '" & ch.Text & "'"
  ElseIf ch.Type = "GuiTextField" Or ch.Type = "GuiCTextField" Then
    WScript.Echo "  FLD " & Mid(ch.Id, InStr(ch.Id,"/usr/")+5) & " = '" & ch.Text & "'"
  End If
  Err.Clear
  On Error GoTo 0
Next

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 500
End Sub
