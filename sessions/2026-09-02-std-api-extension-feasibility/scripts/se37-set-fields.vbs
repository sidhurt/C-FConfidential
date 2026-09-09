Option Explicit
' In a SAP structure/table editor screen, sets one or more fields then optionally goes Back (F3).
' Usage: se37-set-fields.vbs [BACK|STAY] <fieldid>=<value> [<fieldid>=<value> ...]
' Field ids are relative to wnd[0]/usr, e.g. txt[1,3]
' DOES NOT EXECUTE ANY FUNCTION MODULE.

Dim SapGuiAuto, app, conn, sess, i, arg, p, fid, val, mode

If WScript.Arguments.Count < 2 Then WScript.Echo "ERR usage: [BACK|STAY] f=v ..." : WScript.Quit 2
mode = UCase(WScript.Arguments(0))

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If

WScript.Echo "ON=" & sess.FindById("wnd[0]").Text

For i = 1 To WScript.Arguments.Count - 1
  arg = WScript.Arguments(i)
  p = InStr(arg, "=")
  If p > 1 Then
    fid = Left(arg, p - 1)
    val = Mid(arg, p + 1)
    On Error Resume Next
    Err.Clear
    sess.FindById("wnd[0]/usr/" & fid).Text = val
    If Err.Number <> 0 Then
      WScript.Echo "FAIL " & fid & " : " & Err.Description
      Err.Clear
    Else
      WScript.Echo "SET  " & fid & " = " & val
    End If
    On Error GoTo 0
  End If
Next

WScript.Sleep 400

If mode = "BACK" Then
  sess.FindById("wnd[0]").SendVKey 3   ' F3 = Back
  WScript.Sleep 1500
  WScript.Echo "AFTER_BACK=" & sess.FindById("wnd[0]").Text
  If sess.Children.Count > 1 Then WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text
End If
