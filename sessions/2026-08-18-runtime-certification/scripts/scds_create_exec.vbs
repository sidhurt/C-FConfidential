Option Explicit
' EVIDENCE RUN: SD_SCDS_CREATE in DS4/200 against an existing shipment.
' Populates C_REFOBJ_RANGE (VBTYP + REBEL), sets I_FKART, executes once.
' I_OPT_COMMIT defaults to 'X' - this call persists.
Dim sapGuiAuto, app, conn, sess, elapsed, k, ch, u, vbtyp, rebel, fkart, f

vbtyp = WScript.Arguments(0)
rebel = WScript.Arguments(1)
fkart = WScript.Arguments(2)

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If InStr(sess.FindById("wnd[0]").Text, "C_REFOBJ_RANGE") = 0 Then
  WScript.Echo "ABORT|NOT_ON_REFOBJ|" & sess.FindById("wnd[0]").Text : WScript.Quit 11
End If

sess.FindById("wnd[0]/usr/txt[1,6]").Text = vbtyp
sess.FindById("wnd[0]/usr/txt[6,6]").Text = rebel
Ready 15000
WScript.Echo "INPUT|C_REFOBJ_RANGE[1]|VBTYP=" & sess.FindById("wnd[0]/usr/txt[1,6]").Text & _
             "|REBEL=" & sess.FindById("wnd[0]/usr/txt[6,6]").Text

sess.FindById("wnd[0]").SendVKey 3
Ready 60000
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_BACK|" & sess.FindById("wnd[1]").Text : WScript.Quit 12
End If

' I_FKART sits on row 10 of the test screen
On Error Resume Next
Set f = Nothing
Set f = sess.FindById("wnd[0]/usr/txt[34,10]")
If Err.Number <> 0 Then
  Err.Clear
  Set f = sess.FindById("wnd[0]/usr/ctxt[34,10]")
End If
If Err.Number <> 0 Then
  WScript.Echo "FKART_FIELD_NOT_FOUND|" & Err.Description
  Err.Clear
Else
  f.Text = fkart
  WScript.Echo "INPUT|I_FKART|" & f.Text
End If
On Error GoTo 0
Ready 10000

WScript.Echo "PRE_EXEC|I_OPT_COMMIT=" & sess.FindById("wnd[0]/usr/txt[34,9]").Text
WScript.Echo "PRE_EXEC|C_REFOBJ_RANGE=" & sess.FindById("wnd[0]/usr/lbl[37,17]").Text

sess.FindById("wnd[0]").SendVKey 8
Ready 300000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_EXEC|" & sess.FindById("wnd[1]").Text & "|left open"
  WScript.Quit 13
End If

WScript.Echo "POST_EXEC|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "POST_EXEC|sbar=" & sess.FindById("wnd[0]/sbar").Text
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If Len(Trim(ch.Text)) > 0 Then
    WScript.Echo "  " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & " = '" & ch.Text & "'"
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
  WScript.Sleep 1200
End Sub
