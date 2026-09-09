Option Explicit
' Dumps the application toolbar buttons of the current screen. Read-only.
Dim SapGuiAuto, app, conn, sess, i, b, bars, bi

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text
bars = Array("tbar[1]", "tbar[0]")
For bi = 0 To UBound(bars)
  WScript.Echo "--- " & bars(bi)
  For i = 0 To 40
    On Error Resume Next
    Err.Clear
    Set b = sess.FindById("wnd[0]/" & bars(bi) & "/btn[" & i & "]")
    If Err.Number = 0 Then
      WScript.Echo "  btn[" & i & "] tip='" & b.Tooltip & "' text='" & b.Text & "'"
    End If
    Err.Clear
    On Error GoTo 0
  Next
Next
