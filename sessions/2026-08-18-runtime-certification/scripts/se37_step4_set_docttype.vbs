Option Explicit
' STEP 4 (input only, no execution): confirm the POHEADER DOC_TYPE field by tooltip,
' set it to ZP06, return to the test screen, then drill into POHEADERX and dump it.
Dim sapGuiAuto, app, conn, sess, elapsed, ids, i, f

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "ABORT|WRONG_SYSTEM_OR_CLIENT|" & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_ALREADY_OPEN|" & sess.FindById("wnd[1]").Text
  WScript.Quit 10
End If
If InStr(sess.FindById("wnd[0]").Text, "Structure Editor") = 0 Or _
   InStr(sess.FindById("wnd[0]").Text, "POHEADER") = 0 Then
  WScript.Echo "ABORT|UNEXPECTED_SCREEN|" & sess.FindById("wnd[0]").Text
  WScript.Quit 11
End If

WScript.Echo "SCREEN|" & sess.FindById("wnd[0]").Text
WScript.Echo "--- tooltips of candidate columns on row 3 ---"
ids = Array("1,3", "12,3", "17,3", "22,3", "24,3")
For i = 0 To UBound(ids)
  On Error Resume Next
  Set f = sess.FindById("wnd[0]/usr/txt[" & ids(i) & "]")
  If Err.Number = 0 Then
    WScript.Echo "  txt[" & ids(i) & "] tip='" & f.Tooltip & "' value='" & f.Text & "'"
  End If
  Err.Clear
  On Error GoTo 0
Next

' --- set DOC_TYPE ---
sess.FindById("wnd[0]/usr/txt[17,3]").Text = "ZP06"
Ready 15000
WScript.Echo "SET|wnd[0]/usr/txt[17,3]|POHEADER-DOC_TYPE|ZP06|readback='" & _
  sess.FindById("wnd[0]/usr/txt[17,3]").Text & "'"

' --- back to the test screen (F3) ---
sess.FindById("wnd[0]").SendVKey 3
Ready 60000
If sess.Children.Count > 1 Then
  WScript.Echo "STOP|UNEXPECTED_MODAL_AFTER_BACK|" & sess.FindById("wnd[1]").Text
  WScript.Quit 12
End If
WScript.Echo "AFTER_BACK|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "AFTER_BACK|POHEADER_row_value='" & sess.FindById("wnd[0]/usr/lbl[37,9]").Text & "'"
WScript.Echo "AFTER_BACK|TESTRUN='" & sess.FindById("wnd[0]/usr/txt[34,12]").Text & "'"

' --- drill into POHEADERX (row 10) ---
sess.FindById("wnd[0]/usr/lbl[2,10]").SetFocus
sess.FindById("wnd[0]/usr/lbl[2,10]").CaretPosition = 3
sess.FindById("wnd[0]").SendVKey 2
Ready 60000
If sess.Children.Count > 1 Then
  WScript.Echo "STOP|UNEXPECTED_MODAL_POHEADERX|" & sess.FindById("wnd[1]").Text
  WScript.Quit 13
End If
WScript.Echo "POHEADERX|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "--- POHEADERX labels (row 1) and fields (row 3) ---"
Dim u, k, ch
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If ch.Type = "GuiLabel" Or ch.Type = "GuiTextField" Then
    WScript.Echo "  [" & ch.Type & "] " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & _
      " text='" & ch.Text & "' tip='" & ch.Tooltip & "'"
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
  WScript.Sleep 700
End Sub
