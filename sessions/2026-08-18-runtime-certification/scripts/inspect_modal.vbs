Option Explicit
' READ-ONLY: describe the currently open modal without touching it.
Dim sapGuiAuto, app, conn, sess, i, k, ch, w

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

WScript.Echo "SYSTEM=" & sess.Info.SystemName & "|CLIENT=" & sess.Info.Client & "|TCODE=" & sess.Info.Transaction
WScript.Echo "WINDOWS=" & sess.Children.Count
If sess.Children.Count < 2 Then
  WScript.Echo "NO_MODAL_OPEN"
  WScript.Quit 0
End If

For i = 1 To sess.Children.Count - 1
  Set w = sess.Children.Item(CLng(i))
  WScript.Echo "--- wnd[" & i & "] type=" & w.Type & " title='" & w.Text & "'"
  On Error Resume Next
  For k = 0 To w.FindById("usr").Children.Count - 1
    Set ch = w.FindById("usr").Children.Item(CLng(k))
    If Len(Trim(ch.Text)) > 0 Then
      WScript.Echo "    [" & ch.Type & "] " & Replace(ch.Id, "/app/con[0]/ses[0]/wnd[" & i & "]/usr/", "") & " = '" & ch.Text & "'"
    End If
  Next
  Err.Clear
  ' toolbar buttons of the modal
  For k = 0 To 25
    Dim b
    Set b = Nothing
    Set b = w.FindById("tbar[0]/btn[" & k & "]")
    If Err.Number = 0 And Not b Is Nothing Then
      WScript.Echo "    [btn] tbar[0]/btn[" & k & "] text='" & b.Text & "' tip='" & b.Tooltip & "'"
    End If
    Err.Clear
  Next
  On Error GoTo 0
Next
