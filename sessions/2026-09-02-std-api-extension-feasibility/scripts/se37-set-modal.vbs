Option Explicit
' Sets fields in the SE37 single-entry modal (wnd[1]) and reports the label next to each.
' Usage: se37-set-modal.vbs <row>=<value> [<row>=<value> ...]
' Row is the dynpro row number; field is txt[43,<row>], label is lbl[12,<row>].
' DOES NOT EXECUTE ANY FUNCTION MODULE.

Dim SapGuiAuto, app, conn, sess, i, arg, p, r, val, lab

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If
If sess.Children.Count < 2 Then
  WScript.Echo "ABORT no modal open" : WScript.Quit 10
End If

WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text

For i = 0 To WScript.Arguments.Count - 1
  arg = WScript.Arguments(i)
  p = InStr(arg, "=")
  If p > 1 Then
    r = Left(arg, p - 1)
    val = Mid(arg, p + 1)
    lab = "?"
    On Error Resume Next
    Err.Clear
    lab = sess.FindById("wnd[1]/usr/lbl[12," & r & "]").Text
    Err.Clear
    sess.FindById("wnd[1]/usr/txt[43," & r & "]").Text = val
    If Err.Number <> 0 Then
      WScript.Echo "FAIL row " & r & " (" & lab & ") : " & Err.Description
      Err.Clear
    Else
      WScript.Echo "SET  row " & r & "  " & lab & " = '" & val & "'"
    End If
    On Error GoTo 0
  End If
Next
