Option Explicit
' Drill into a structure row on the SE37 test screen, switch to the vertical
' Single Entry view, and dump every field with its control id.
' Usage: se37_single_entry.vbs <labelRow>
Dim sapGuiAuto, app, conn, sess, elapsed, row, k, ch, u, b, i

row = WScript.Arguments(0)

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If

sess.FindById("wnd[0]/usr/lbl[2," & row & "]").SetFocus
sess.FindById("wnd[0]/usr/lbl[2," & row & "]").CaretPosition = 3
sess.FindById("wnd[0]").SendVKey 2
Ready 60000
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_DRILL|" & sess.FindById("wnd[1]").Text : WScript.Quit 11
End If
WScript.Echo "STRUCT|" & sess.FindById("wnd[0]").Text

' find and press the Single Entry button on the structure editor toolbar
Dim pressed
pressed = False
For i = 0 To 40
  On Error Resume Next
  Set b = Nothing
  Set b = sess.FindById("wnd[0]/tbar[1]/btn[" & i & "]")
  If Err.Number = 0 And Not b Is Nothing Then
    If InStr(b.Tooltip, "Single Entry") > 0 Then
      b.Press
      pressed = True
    End If
  End If
  Err.Clear
  On Error GoTo 0
  If pressed Then Exit For
Next
If Not pressed Then
  WScript.Echo "NO_SINGLE_ENTRY_BUTTON"
  WScript.Quit 12
End If
Ready 60000

WScript.Echo "VIEW|" & sess.FindById("wnd[0]").Text
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  Dim sid
  sid = ch.Id
  sid = Mid(sid, InStr(sid, "/usr/") + 5)
  If ch.Type = "GuiLabel" Or ch.Type = "GuiTextField" Or ch.Type = "GuiCTextField" Then
    WScript.Echo "  [" & ch.Type & "] " & sid & " = '" & ch.Text & "'"
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
  WScript.Sleep 800
End Sub
