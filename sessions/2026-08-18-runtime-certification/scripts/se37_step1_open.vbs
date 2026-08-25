Option Explicit
' STEP 1 (read-only): on the SE37 initial screen, set the function-module name
' and report the application-toolbar button identities. Presses nothing.
Dim sapGuiAuto, app, conn, sess, elapsed, i, b, ids

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "ABORT|WRONG_SYSTEM_OR_CLIENT|" & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|UNEXPECTED_MODAL|" & sess.FindById("wnd[1]").Text
  WScript.Quit 10
End If
If sess.Info.Transaction <> "SE37" Then
  WScript.Echo "ABORT|NOT_ON_SE37|" & sess.Info.Transaction
  WScript.Quit 11
End If

sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = "BAPI_PO_CREATE1"
Ready 10000

WScript.Echo "FIELD|wnd[0]/usr/ctxtRS38L-NAME|" & sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text
WScript.Echo "SCREEN|" & sess.Info.Program & "|" & sess.Info.ScreenNumber

ids = Array("26","27","8","39","32","14","29","30","31")
For i = 0 To UBound(ids)
  On Error Resume Next
  Set b = sess.FindById("wnd[0]/tbar[1]/btn[" & ids(i) & "]")
  If Err.Number = 0 Then
    WScript.Echo "TBAR1|btn[" & ids(i) & "]|text='" & b.Text & "'|tip='" & b.Tooltip & "'"
  End If
  Err.Clear
  On Error GoTo 0
Next

WScript.Echo "WINDOWS|" & sess.Children.Count

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 500
End Sub
