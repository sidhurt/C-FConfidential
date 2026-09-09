Option Explicit
' Switches the table editor to Single Entry view and dumps label/field pairs. Read-only.
' Optional arg: FILTER string to only show matching labels.
Dim SapGuiAuto, app, conn, sess, filt

filt = ""
If WScript.Arguments.Count > 0 Then filt = UCase(WScript.Arguments(0))

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If

If InStr(sess.FindById("wnd[0]").Text, "Single") = 0 Then
  sess.FindById("wnd[0]/tbar[1]/btn[19]").Press
  WScript.Sleep 2000
End If

WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text

Dim root
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text
  WScript.Echo "DUMPING wnd[1]"
  Set root = sess.FindById("wnd[1]/usr")
Else
  Set root = sess.FindById("wnd[0]/usr")
End If

Dump root, filt

Sub Dump(node, f)
  Dim k, kid, t, nm
  On Error Resume Next
  t = node.Type : nm = node.Text
  If t = "GuiLabel" Or t = "GuiTextField" Or t = "GuiCTextField" Then
    If f = "" Or InStr(UCase(nm), f) > 0 Then
      WScript.Echo Replace(node.Id, "/app/con[0]/ses[0]/wnd[0]/usr/", "") & " [" & t & "] '" & Left(nm, 35) & "'"
    End If
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set kid = node.Children.Item(CLng(k))
      Dump kid, f
    Next
  End If
  On Error GoTo 0
End Sub
