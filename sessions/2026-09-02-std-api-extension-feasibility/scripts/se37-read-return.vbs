Option Explicit
' On the SE37 Result Screen, locates the RETURN table, opens it and dumps the rows.
' Read-only. Executes nothing.

Dim SapGuiAuto, app, conn, sess, r, lab, found, foundRow, i, j

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If

WScript.Echo "SCREEN=" & sess.FindById("wnd[0]").Text

' list all table rows on the result screen
found = False
For r = 14 To 45
  On Error Resume Next
  Err.Clear
  lab = sess.FindById("wnd[0]/usr/lbl[2," & r & "]").Text
  If Err.Number = 0 And Len(Trim(lab)) > 0 Then
    Dim v
    Err.Clear
    v = sess.FindById("wnd[0]/usr/lbl[37," & r & "]").Text
    WScript.Echo "  row " & r & "  " & lab & "  |  " & Trim(v)
    If UCase(Trim(lab)) = "RETURN" Then
      found = True
      foundRow = r
    End If
  End If
  Err.Clear
  On Error GoTo 0
Next

If Not found Then WScript.Echo "ERR RETURN row not found" : WScript.Quit 3

WScript.Echo "--- opening RETURN at row " & foundRow
sess.FindById("wnd[0]/usr/lbl[2," & foundRow & "]").SetFocus
sess.FindById("wnd[0]").SendVKey 2
WScript.Sleep 2500

WScript.Echo "TITLE=" & sess.FindById("wnd[0]").Text
If sess.Children.Count > 1 Then WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text

' dump the visible grid rows: labels row 4 are headers, data from row 6
For i = 4 To 30
  Dim line, cell, anyv
  line = "" : anyv = False
  For j = 0 To 200
    On Error Resume Next
    Err.Clear
    cell = sess.FindById("wnd[0]/usr/txt[" & j & "," & i & "]").Text
    If Err.Number = 0 Then
      If Len(Trim(cell)) > 0 Then line = line & "[" & j & "]" & Trim(cell) & "  " : anyv = True
    Else
      Err.Clear
      cell = sess.FindById("wnd[0]/usr/lbl[" & j & "," & i & "]").Text
      If Err.Number = 0 And Len(Trim(cell)) > 0 Then line = line & "<" & j & ">" & Trim(cell) & "  " : anyv = True
    End If
    Err.Clear
    On Error GoTo 0
  Next
  If anyv Then WScript.Echo "r" & i & ": " & Left(line, 250)
Next
