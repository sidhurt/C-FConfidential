Option Explicit
' READ-ONLY QS4/700 SE16 exporter.
' USAGE:
'   qs4_se16_export.vbs COUNT  <TABLE> [FIELD=LOW[..HIGH]] ...
'   qs4_se16_export.vbs EXPORT <TABLE> <OUT_DIR> <OUT_FILE> [FIELD=LOW[..HIGH]] ...
' COUNT uses SE16 "Number of Entries" (no grid). EXPORT runs the selection with no hit limit and
' saves the ALV grid through SAP's own List > Export > Local File, tab-delimited text.
' It never answers a popup it does not recognise (including SAP GUI security prompts): it reports
' the popup text and stops.
Dim app, conn, s, sess, found, i, j, mode, tbl, outDir, outFile, firstFilter
Dim lbl, n, nameOf, arg, eq, fn, fv, hi, k, g, elapsed, fso, t0

If WScript.Arguments.Count < 2 Then WScript.Echo "USAGE" : WScript.Quit 1
mode = UCase(WScript.Arguments(0))
tbl = UCase(WScript.Arguments(1))
If mode = "EXPORT" Then
  If WScript.Arguments.Count < 4 Then WScript.Echo "USAGE" : WScript.Quit 1
  outDir = WScript.Arguments(2) : outFile = WScript.Arguments(3) : firstFilter = 4
Else
  firstFilter = 2
End If

Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_QS4_700" : WScript.Quit 9
WScript.Echo "SESSION|" & sess.Info.SystemName & "/" & sess.Info.Client & "|User=" & sess.Info.User
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_BEFORE|" & SafeText("wnd[1]") : WScript.Quit 10

sess.StartTransaction "SE16"
Ready 20000
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 20000
If sess.Children.Count > 1 Then
  If SafeText("wnd[1]") = "Select Fields for Selection" Then
    sess.FindById("wnd[1]").SendVKey 0 : Ready 20000
  Else
    WScript.Echo "ABORT|UNEXPECTED_MODAL|" & SafeText("wnd[1]") : WScript.Quit 12
  End If
End If

Set nameOf = CreateObject("Scripting.Dictionary")
For n = 1 To 40
  lbl = ""
  On Error Resume Next
  lbl = sess.FindById("wnd[0]/usr/txt%_I" & n & "_%_APP_%-TEXT").Text
  Err.Clear
  On Error GoTo 0
  lbl = UCase(Trim(lbl))
  If Len(lbl) > 0 Then
    If Not nameOf.Exists(lbl) Then nameOf.Add lbl, n
  End If
Next

For i = firstFilter To WScript.Arguments.Count - 1
  arg = CStr(WScript.Arguments(i))
  eq = InStr(arg, "=")
  If eq > 1 Then
    fn = UCase(Left(arg, eq - 1)) : fv = Mid(arg, eq + 1) : hi = ""
    k = InStr(fv, "..")
    If k > 0 Then hi = Mid(fv, k + 2) : fv = Left(fv, k - 1)
    If Not nameOf.Exists(fn) Then WScript.Echo "ABORT|SELECTION_FIELD_NOT_ON_SCREEN|" & fn & "|available=" & Join(nameOf.Keys, ",") : WScript.Quit 15
    n = nameOf(fn)
    If Not SetField("wnd[0]/usr/ctxtI" & n & "-LOW", fv) Then SetField "wnd[0]/usr/txtI" & n & "-LOW", fv
    If Len(hi) > 0 Then
      If Not SetField("wnd[0]/usr/ctxtI" & n & "-HIGH", hi) Then SetField "wnd[0]/usr/txtI" & n & "-HIGH", hi
    End If
    WScript.Echo "FILTER|" & fn & "=" & fv & IIfS(Len(hi) > 0, ".." & hi, "")
  End If
Next

If mode = "COUNT" Then
  ' Number of Entries: toolbar button on the selection screen
  On Error Resume Next
  sess.FindById("wnd[0]/tbar[1]/btn[31]").Press
  If Err.Number <> 0 Then Err.Clear : WScript.Echo "ABORT|NO_COUNT_BUTTON" : WScript.Quit 20
  On Error GoTo 0
  Ready 600000
  If sess.Children.Count > 1 Then
    WScript.Echo "COUNT_POPUP|" & SafeText("wnd[1]") & "|" & PopupText()
    sess.FindById("wnd[1]").SendVKey 0 : Ready 10000
  Else
    WScript.Echo "COUNT|SBAR=" & SafeText("wnd[0]/sbar")
  End If
  WScript.Quit 0
End If

' EXPORT: remove the hit limit
On Error Resume Next
sess.FindById("wnd[0]/usr/txtMAX_SEL").Text = ""
Err.Clear
On Error GoTo 0
t0 = Timer
sess.FindById("wnd[0]").SendVKey 8
Ready 1800000
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_AFTER_EXEC|" & SafeText("wnd[1]") & "|" & PopupText() : WScript.Quit 13
Set g = FindGrid(sess.FindById("wnd[0]/usr"), 0)
If g Is Nothing Then WScript.Echo "NO_GRID|SBAR=" & SafeText("wnd[0]/sbar") : WScript.Quit 0
WScript.Echo "GRID|Rows=" & g.RowCount & "|Cols=" & g.ColumnCount & "|secs=" & Round(Timer - t0)

' List > Export > Local File (ALV toolbar menu), format "Text with Tabs"
On Error Resume Next
g.PressToolbarContextButton "&MB_EXPORT"
g.SelectContextMenuItem "&PC"
If Err.Number <> 0 Then
  Err.Clear
  sess.FindById("wnd[0]/mbar/menu[0]/menu[3]/menu[2]").Select
End If
On Error GoTo 0
Ready 20000
If sess.Children.Count < 2 Then WScript.Echo "ABORT|NO_EXPORT_DIALOG" : WScript.Quit 30
WScript.Echo "DIALOG1|" & SafeText("wnd[1]")
' choose the "Text with Tabs" radio: find it by its label
If Not ChooseRadio("wnd[1]/usr", "TABS") Then WScript.Echo "ABORT|NO_TABS_OPTION|" & PopupText() : WScript.Quit 31
sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
Ready 20000
If sess.Children.Count < 2 Then WScript.Echo "ABORT|NO_FILE_DIALOG" : WScript.Quit 32
WScript.Echo "DIALOG2|" & SafeText("wnd[1]")
If Not SetField("wnd[1]/usr/ctxtDY_PATH", outDir) Then WScript.Echo "ABORT|NO_PATH_FIELD|" & PopupText() : WScript.Quit 33
SetField "wnd[1]/usr/ctxtDY_FILENAME", outFile
SetField "wnd[1]/usr/ctxtDY_FILE_ENCODING", "4110"
' Replace (overwrite) if present, else Generate
On Error Resume Next
sess.FindById("wnd[1]/tbar[0]/btn[11]").Press
If Err.Number <> 0 Then Err.Clear : sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
On Error GoTo 0

Set fso = CreateObject("Scripting.FileSystemObject")
elapsed = 0
Do While elapsed < 900000
  WScript.Sleep 2000 : elapsed = elapsed + 2000
  If fso.FileExists(outDir & "\" & outFile) And Not sess.Busy Then Exit Do
Loop
If sess.Children.Count > 1 Then WScript.Echo "STOPPED_AT_POPUP|" & SafeText("wnd[1]") & "|" & PopupText() : WScript.Quit 40
If fso.FileExists(outDir & "\" & outFile) Then
  WScript.Echo "SAVED|" & outDir & "\" & outFile & "|bytes=" & fso.GetFile(outDir & "\" & outFile).Size & "|SBAR=" & SafeText("wnd[0]/sbar")
Else
  WScript.Echo "NOT_SAVED|SBAR=" & SafeText("wnd[0]/sbar") & "|busy=" & sess.Busy
End If

Function ChooseRadio(containerId, needle)
  Dim c, ch, idx
  ChooseRadio = False
  On Error Resume Next
  Set c = sess.FindById(containerId)
  ChooseRadio = WalkRadio(c, needle, 0)
  On Error GoTo 0
End Function
Function WalkRadio(node, needle, depth)
  Dim idx, ch
  WalkRadio = False
  If depth > 6 Then Exit Function
  On Error Resume Next
  If node.Type = "GuiRadioButton" Then
    If InStr(UCase(node.Text), needle) > 0 Then node.Select : WalkRadio = True : Exit Function
  End If
  If node.ContainerType = True Then
    For idx = 0 To node.Children.Count - 1
      Set ch = node.Children.Item(CLng(idx))
      If WalkRadio(ch, needle, depth + 1) Then WalkRadio = True : Exit Function
    Next
  End If
End Function
Function PopupText()
  Dim t, idx, c
  t = ""
  On Error Resume Next
  Set c = sess.FindById("wnd[1]/usr")
  For idx = 0 To c.Children.Count - 1
    t = t & " " & c.Children.Item(CLng(idx)).Text
  Next
  PopupText = Replace(Replace(Trim(t), vbCr, " "), vbLf, " ")
End Function
Function SetField(id, val)
  SetField = False
  On Error Resume Next
  Err.Clear
  sess.FindById(id).Text = val
  If Err.Number = 0 Then SetField = True
  Err.Clear
  On Error GoTo 0
End Function
Function IIfS(cond, a, b)
  If cond Then IIfS = a Else IIfS = b
End Function
Function FindGrid(node, depth)
  Dim k2, ch, res
  Set FindGrid = Nothing
  If depth > 8 Then Exit Function
  On Error Resume Next
  If node.Type = "GuiShell" Then
    If node.SubType = "GridView" Then Set FindGrid = node : Exit Function
  End If
  If node.ContainerType = True Then
    For k2 = 0 To node.Children.Count - 1
      Set ch = node.Children.Item(CLng(k2))
      Set res = FindGrid(ch, depth + 1)
      If Not res Is Nothing Then Set FindGrid = res : Exit Function
    Next
  End If
  On Error GoTo 0
End Function
Function SafeText(id)
  On Error Resume Next : Err.Clear : SafeText = sess.FindById(id).Text
  If Err.Number <> 0 Then SafeText = "" : Err.Clear
  On Error GoTo 0
End Function
Sub Ready(maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 500
End Sub
