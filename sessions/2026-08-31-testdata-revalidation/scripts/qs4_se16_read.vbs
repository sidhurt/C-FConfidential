Option Explicit
' READ-ONLY QS4/700 SE16 reader.
' Maps selection fields BY NAME (reads the I<n> labels). Dumps ONLY requested columns.
' USAGE: qs4_se16_read.vbs <TABLE> <MAXROWS> <COLS_CSV> [FIELD=LOW[..HIGH]] ...
Dim app, conn, s, sess, found, i, j, tbl, maxRows, colsCsv, cols, elapsed
Dim lbl, n, nameOf, idOf, arg, eq, fn, fv, hi, k, g, r, c, line, v, dumped

If WScript.Arguments.Count < 3 Then WScript.Echo "USAGE|TABLE MAXROWS COLS_CSV [FIELD=LOW[..HIGH]]" : WScript.Quit 1
tbl     = UCase(CStr(WScript.Arguments(0)))
maxRows = CLng(WScript.Arguments(1))
colsCsv = UCase(CStr(WScript.Arguments(2)))
cols    = Split(colsCsv, ",")

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
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_AFTER_NAV|" & SafeText("wnd[1]") : WScript.Quit 11
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 20000
If sess.Children.Count > 1 Then
  If SafeText("wnd[1]") = "Select Fields for Selection" Then
    sess.FindById("wnd[1]").SendVKey 0
    Ready 20000
  Else
    WScript.Echo "ABORT|UNEXPECTED_MODAL|" & SafeText("wnd[1]") : WScript.Quit 12
  End If
End If

' --- map selection-field names to I<n> ---
Set nameOf = CreateObject("Scripting.Dictionary")
Set idOf   = CreateObject("Scripting.Dictionary")
For n = 1 To 30
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

' --- apply filters ---
For i = 3 To WScript.Arguments.Count - 1
  arg = CStr(WScript.Arguments(i))
  eq = InStr(arg, "=")
  If eq > 1 Then
    fn = UCase(Left(arg, eq - 1))
    fv = Mid(arg, eq + 1)
    hi = ""
    k = InStr(fv, "..")
    If k > 0 Then hi = Mid(fv, k + 2) : fv = Left(fv, k - 1)
    If nameOf.Exists(fn) Then
      n = nameOf(fn)
      If Not SetField("wnd[0]/usr/ctxtI" & n & "-LOW", fv) Then
        If Not SetField("wnd[0]/usr/txtI" & n & "-LOW", fv) Then
          WScript.Echo "WARN|CANNOT_SET|" & fn
        End If
      End If
      If Len(hi) > 0 Then
        If Not SetField("wnd[0]/usr/ctxtI" & n & "-HIGH", hi) Then
          SetField "wnd[0]/usr/txtI" & n & "-HIGH", hi
        End If
      End If
      WScript.Echo "FILTER|" & fn & "(I" & n & ")=" & fv & IIfS(Len(hi) > 0, ".." & hi, "")
    Else
      WScript.Echo "ABORT|SELECTION_FIELD_NOT_ON_SCREEN|" & fn & "|available=" & Join(nameOf.Keys, ",")
      WScript.Quit 15
    End If
  End If
Next

On Error Resume Next
sess.FindById("wnd[0]/usr/txtMAX_SEL").Text = CStr(maxRows)
Err.Clear
On Error GoTo 0

sess.FindById("wnd[0]").SendVKey 8
Ready 90000
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_AFTER_EXEC|" & SafeText("wnd[1]") : WScript.Quit 13

Set g = FindGrid(sess.FindById("wnd[0]/usr"), 0)
If g Is Nothing Then
  WScript.Echo "NO_GRID|Title=" & Clean(SafeText("wnd[0]")) & "|SBAR=" & Clean(SafeText("wnd[0]/sbar"))
  WScript.Quit 0
End If
WScript.Echo "RESULT|Table=" & tbl & "|Rows=" & g.RowCount & "|SBAR=" & Clean(SafeText("wnd[0]/sbar"))
WScript.Echo "COLS|" & colsCsv
dumped = 0
For r = 0 To g.RowCount - 1
  If dumped >= maxRows Then WScript.Echo "STOPPED_AT|" & maxRows : Exit For
  If g.VisibleRowCount > 0 And (r Mod g.VisibleRowCount) = 0 Then
    On Error Resume Next : g.FirstVisibleRow = r : Err.Clear : On Error GoTo 0
  End If
  line = "ROW" & r
  For c = 0 To UBound(cols)
    v = "<NA>"
    On Error Resume Next
    Err.Clear
    v = g.GetCellValue(CLng(r), Trim(cols(c)))
    If Err.Number <> 0 Then v = "<NA>" : Err.Clear
    On Error GoTo 0
    line = line & "|" & Trim(cols(c)) & "=" & Clean(v)
  Next
  WScript.Echo line
  dumped = dumped + 1
Next

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
Function Clean(v)
  Dim t : t = CStr(v) : t = Replace(t, vbCr, " ") : t = Replace(t, vbLf, " ") : t = Replace(t, vbTab, " ") : t = Replace(t, "|", "/") : Clean = t
End Function
Sub Ready(maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 500
End Sub
