Option Explicit
' After a test run, returns to the Result Screen and reads GOODSMVT_ITEM entry 1
' in single-entry view to see which fields SAP populated. Read-only.

Dim SapGuiAuto, app, conn, sess, guard, r

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If

guard = 0
Do While InStr(sess.FindById("wnd[0]").Text, "Result Screen") = 0 And guard < 6
  If sess.Children.Count > 1 Then
    sess.FindById("wnd[1]").SendVKey 0
  Else
    sess.FindById("wnd[0]").SendVKey 3
  End If
  WScript.Sleep 1500
  guard = guard + 1
Loop
WScript.Echo "SCREEN=" & sess.FindById("wnd[0]").Text

sess.FindById("wnd[0]/usr/lbl[2,27]").SetFocus
sess.FindById("wnd[0]").SendVKey 2
WScript.Sleep 2200
WScript.Echo "TABLE=" & sess.FindById("wnd[0]").Text

sess.FindById("wnd[0]/tbar[1]/btn[19]").Press
WScript.Sleep 2200
If sess.Children.Count < 2 Then WScript.Echo "ABORT no single-entry modal" : WScript.Quit 14
WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text

ShowAt 0
ShowAt 40
ShowAt 68
ShowAt 104

Sub ShowAt(vpos)
  Dim i, lab, val
  On Error Resume Next
  Err.Clear
  sess.FindById("wnd[1]/usr").VerticalScrollbar.Position = vpos
  Err.Clear
  On Error GoTo 0
  WScript.Sleep 900
  For i = 0 To 40
    lab = "" : val = ""
    On Error Resume Next
    Err.Clear
    lab = sess.FindById("wnd[1]/usr/lbl[12," & i & "]").Text
    If Err.Number = 0 And Len(Trim(lab)) > 0 Then
      Err.Clear
      val = sess.FindById("wnd[1]/usr/txt[43," & i & "]").Text
      If Err.Number <> 0 Then
        Err.Clear
        val = sess.FindById("wnd[1]/usr/lbl[43," & i & "]").Text
      End If
      If Len(Trim(val)) > 0 And Trim(val) <> "0.000" And Trim(val) <> "000000" And Trim(val) <> "0000" And Trim(val) <> "0" Then
        WScript.Echo "  " & Trim(lab) & " = '" & Trim(val) & "'"
      End If
    End If
    Err.Clear
    On Error GoTo 0
  Next
End Sub
