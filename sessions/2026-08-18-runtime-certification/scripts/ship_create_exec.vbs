Option Explicit
' EVIDENCE RUN: BAPI_SHIPMENT_CREATE in DS4/200.
' Sets HEADERDATA SHIPMENT_TYPE + TRANS_PLAN_PT, returns to the test screen and
' executes ONCE.  This BAPI has no TESTRUN - the call is a real create.
Dim sapGuiAuto, app, conn, sess, elapsed, k, ch, u, shtyp, tplst

shtyp = WScript.Arguments(0)
tplst = WScript.Arguments(1)

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
End If
If InStr(sess.FindById("wnd[0]").Text, "HEADERDATA") = 0 Then
  WScript.Echo "ABORT|NOT_ON_HEADERDATA|" & sess.FindById("wnd[0]").Text : WScript.Quit 11
End If

sess.FindById("wnd[0]/usr/txt[35,3]").Text = shtyp
sess.FindById("wnd[0]/usr/txt[40,3]").Text = tplst
Ready 15000
WScript.Echo "INPUT|HEADERDATA-SHIPMENT_TYPE|txt[35,3]|" & sess.FindById("wnd[0]/usr/txt[35,3]").Text
WScript.Echo "INPUT|HEADERDATA-TRANS_PLAN_PT|txt[40,3]|" & sess.FindById("wnd[0]/usr/txt[40,3]").Text

sess.FindById("wnd[0]").SendVKey 3          ' back to test screen
Ready 60000
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_BACK|" & sess.FindById("wnd[1]").Text : WScript.Quit 12
End If
WScript.Echo "PRE_EXEC|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "PRE_EXEC|HEADERDATA row=" & sess.FindById("wnd[0]/usr/lbl[37,9]").Text

sess.FindById("wnd[0]").SendVKey 8          ' EXECUTE - real create
Ready 300000

If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_EXEC|" & sess.FindById("wnd[1]").Text & "|left open"
  WScript.Quit 13
End If

WScript.Echo "POST_EXEC|title=" & sess.FindById("wnd[0]").Text
WScript.Echo "POST_EXEC|sbar=" & sess.FindById("wnd[0]/sbar").Text
WScript.Echo "--- RESULT SCREEN ---"
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
