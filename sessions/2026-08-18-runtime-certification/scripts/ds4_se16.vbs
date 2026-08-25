' Read-only SE16 data-browser reader for the STO flow trace.
' Modes:
'   FIELDS <TABLE>                       -> list selection-screen input field ids
'   RUN <TABLE> <MAXROWS> <OUT> [F=V...] -> set fields, execute, dump result grid to TSV
' Never writes to SAP. Execute (F8) on the SE16 selection screen is a read.
Option Explicit

Dim sapGuiAuto, app, connection, session
Dim mode, tableName, maxRows, outPath
Dim i, arg, eqPos, fieldId, fieldVal
Dim fieldIds(), fieldVals(), fieldCount

mode = "" : tableName = "" : maxRows = "200" : outPath = ""
fieldCount = 0
ReDim fieldIds(50) : ReDim fieldVals(50)

If WScript.Arguments.Count < 2 Then
  WScript.Echo "USAGE|FIELDS <TABLE> | RUN <TABLE> <MAXROWS> <OUT> [FIELD=VALUE...]"
  WScript.Quit 1
End If

mode = UCase(WScript.Arguments(0))
tableName = UCase(WScript.Arguments(1))

If mode = "RUN" Then
  If WScript.Arguments.Count < 4 Then
    WScript.Echo "USAGE|RUN <TABLE> <MAXROWS> <OUT> [FIELD=VALUE...]"
    WScript.Quit 1
  End If
  maxRows = WScript.Arguments(2)
  outPath = WScript.Arguments(3)
  For i = 4 To WScript.Arguments.Count - 1
    arg = WScript.Arguments(i)
    eqPos = InStr(arg, "=")
    If eqPos > 1 Then
      fieldIds(fieldCount) = Left(arg, eqPos - 1)
      fieldVals(fieldCount) = Mid(arg, eqPos + 1)
      fieldCount = fieldCount + 1
    End If
  Next
End If

On Error Resume Next
Set sapGuiAuto = GetObject("SAPGUI")
If Err.Number <> 0 Then Bail "GETOBJECT_FAILED", 2
Err.Clear
Set app = sapGuiAuto.GetScriptingEngine
If Err.Number <> 0 Then Bail "SCRIPTING_ENGINE_FAILED", 3
Err.Clear
Set connection = app.Children(CLng(0))
If Err.Number <> 0 Then Bail "CONNECTION_FAILED", 4
Err.Clear
Set session = connection.Children(CLng(0))
If Err.Number <> 0 Then Bail "SESSION_FAILED", 5
On Error GoTo 0
If Clean(session.Info.SystemName) <> "DS4" Then
  WScript.Echo "ABORT|WRONG_SYSTEM|" & Clean(session.Info.SystemName)
  WScript.Quit 9
End If


If Clean(session.Info.Client) <> "200" Then
  WScript.Echo "ABORT|WRONG_CLIENT|" & Clean(session.Info.Client)
  WScript.Quit 9
End If

' --- open SE16 for the table, or a bare transaction when TABLE starts with T: --
If tableName = "CURRENT" Then
  ' inspect whatever is on screen; do not navigate
ElseIf Left(tableName, 2) = "T:" Then
  session.FindById("wnd[0]/tbar[0]/okcd").Text = "/n" & Mid(tableName, 3)
  session.FindById("wnd[0]").SendVKey 0
  Ready 30000
Else
  ' reset to a clean screen first; the session may be parked on a result list
  session.FindById("wnd[0]/tbar[0]/okcd").Text = "/n"
  session.FindById("wnd[0]").SendVKey 0
  Ready 15000
  session.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
  session.FindById("wnd[0]").SendVKey 0
  Ready 20000
  session.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tableName
  session.FindById("wnd[0]").SendVKey 0
  Ready 30000
End If

WScript.Echo "SESSION|System=" & Clean(session.Info.SystemName) & _
  "|Client=" & Clean(session.Info.Client) & _
  "|User=" & Clean(session.Info.User) & _
  "|Transaction=" & Clean(session.Info.Transaction)
WScript.Echo "TABLE|" & tableName
WScript.Echo "STATUS|" & SafeText(session, "wnd[0]/sbar")

If mode = "FIELDS" Then
  DumpInputs session.FindById("wnd[0]/usr"), 0
  WScript.Quit 0
End If

If mode = "PROBE" Then
  ProbeTypes session.FindById("wnd[0]/usr"), 0
  WScript.Quit 0
End If

' --- RUN: set selection fields ----------------------------------------------
For i = 0 To fieldCount - 1
  On Error Resume Next
  Err.Clear
  session.FindById("wnd[0]/usr/" & fieldIds(i)).Text = fieldVals(i)
  If Err.Number <> 0 Then
    WScript.Echo "WARN|SET_FAILED|" & fieldIds(i) & "|" & Err.Description
    Err.Clear
  Else
    WScript.Echo "SET|" & fieldIds(i) & "=" & fieldVals(i)
  End If
  On Error GoTo 0
Next

On Error Resume Next
Err.Clear
session.FindById("wnd[0]/usr/txtMAX_SEL").Text = maxRows
If Err.Number <> 0 Then Err.Clear
On Error GoTo 0

' F8 = execute (read)
session.FindById("wnd[0]").SendVKey 8
Ready 120000

WScript.Echo "STATUS_AFTER|" & SafeText(session, "wnd[0]/sbar")

Dim grid
Set grid = FindGrid(session.FindById("wnd[0]/usr"), 0)
If grid Is Nothing Then
  WScript.Echo "NO_GRID|result may be a classic list or empty selection"
  WScript.Quit 0
End If

DumpGrid grid, outPath
WScript.Quit 0

' --- helpers ----------------------------------------------------------------

Sub ProbeTypes(node, depth)
  Dim t, id, c, k, child
  If depth > 5 Then Exit Sub
  On Error Resume Next
  t = node.Type : id = node.Id
  On Error GoTo 0
  If t <> "GuiLabel" And t <> "GuiTextField" And t <> "GuiCTextField" And t <> "GuiButton" Then
    WScript.Echo "NODE|d=" & depth & "|" & t & "|" & Clean(id)
  End If
  On Error Resume Next
  Err.Clear
  c = node.Children.Count
  If Err.Number <> 0 Then Err.Clear : Exit Sub
  On Error GoTo 0
  If c > 60 Then
    WScript.Echo "NODE|d=" & depth & "|(" & c & " children, not expanded)|" & Clean(id)
    Exit Sub
  End If
  For k = 0 To c - 1
    On Error Resume Next
    Err.Clear
    Set child = node.Children(CLng(k))
    If Err.Number = 0 Then ProbeTypes child, depth + 1
    Err.Clear
    On Error GoTo 0
  Next
End Sub

Sub DumpInputs(node, depth)
  Dim t, id, n, tip, c, k, child
  If depth > 6 Then Exit Sub
  On Error Resume Next
  t = node.Type : id = node.Id : n = node.Name : tip = node.Tooltip
  On Error GoTo 0
  If t = "GuiTextField" Or t = "GuiCTextField" Then
    If InStr(id, "-LOW") > 0 Then
      WScript.Echo "FIELD|" & Mid(id, InStr(id, "/usr/") + 5) & "|Name=" & Clean(n) & "|Tip=" & Clean(tip)
    End If
  End If
  On Error Resume Next
  Err.Clear
  c = node.Children.Count
  If Err.Number <> 0 Then Err.Clear : Exit Sub
  On Error GoTo 0
  For k = 0 To c - 1
    On Error Resume Next
    Err.Clear
    Set child = node.Children(CLng(k))
    If Err.Number = 0 Then DumpInputs child, depth + 1
    Err.Clear
    On Error GoTo 0
  Next
End Sub

Function FindGrid(node, depth)
  Dim t, c, k, child, found
  Set FindGrid = Nothing
  If depth > 8 Then Exit Function
  Dim st
  On Error Resume Next
  t = node.Type
  st = ""
  st = node.SubType
  Err.Clear
  On Error GoTo 0
  If t = "GuiGridView" Or (t = "GuiShell" And st = "GridView") Then
    Set FindGrid = node
    Exit Function
  End If
  On Error Resume Next
  Err.Clear
  c = node.Children.Count
  If Err.Number <> 0 Then Err.Clear : Exit Function
  On Error GoTo 0
  For k = 0 To c - 1
    On Error Resume Next
    Err.Clear
    Set child = node.Children(CLng(k))
    If Err.Number = 0 Then
      Set found = FindGrid(child, depth + 1)
      If Not (found Is Nothing) Then
        Set FindGrid = found
        Exit Function
      End If
    End If
    Err.Clear
    On Error GoTo 0
  Next
End Function

Sub DumpGrid(grid, path)
  Dim fso, out, cols, rowCount, r, c, line, colName, v, n
  Set fso = CreateObject("Scripting.FileSystemObject")
  Set out = fso.CreateTextFile(path, True, True)

  On Error Resume Next
  Set cols = grid.ColumnOrder
  rowCount = grid.RowCount
  On Error GoTo 0

  WScript.Echo "GRID|Rows=" & rowCount & "|Cols=" & cols.Count

  line = ""
  For c = 0 To cols.Count - 1
    colName = cols(c)
    If c > 0 Then line = line & vbTab
    line = line & colName
  Next
  out.WriteLine line

  ' The ALV lazy-loads: GetCellValue only returns data for rows currently in the
  ' grid's buffer. Page through with FirstVisibleRow so every row is materialised.
  Dim vis, pageStart, pageEnd, blanks
  vis = 0
  On Error Resume Next
  vis = grid.VisibleRowCount
  On Error GoTo 0
  If vis < 1 Then vis = 20

  n = 0
  blanks = 0
  pageStart = 0
  Do While pageStart < rowCount
    On Error Resume Next
    Err.Clear
    grid.FirstVisibleRow = CLng(pageStart)
    If Err.Number <> 0 Then Err.Clear
    On Error GoTo 0

    pageEnd = pageStart + vis - 1
    If pageEnd > rowCount - 1 Then pageEnd = rowCount - 1

    For r = pageStart To pageEnd
      line = ""
      For c = 0 To cols.Count - 1
        v = ""
        On Error Resume Next
        Err.Clear
        v = grid.GetCellValue(CLng(r), CStr(cols(c)))
        If Err.Number <> 0 Then v = "" : Err.Clear
        On Error GoTo 0
        If c > 0 Then line = line & vbTab
        line = line & Clean(v)
      Next
      If Replace(Replace(line, vbTab, ""), " ", "") = "" Then blanks = blanks + 1
      out.WriteLine line
      n = n + 1
      If n >= 3000 Then Exit For
    Next
    If n >= 3000 Then Exit Do
    pageStart = pageEnd + 1
  Loop
  WScript.Echo "PAGED|visibleRowCount=" & vis & "|blankRows=" & blanks
  out.Close
  WScript.Echo "WROTE|" & path & "|Rows=" & n
End Sub

Sub Ready(maxMs)
  Dim e
  e = 0
  Do While session.Busy And e < maxMs
    WScript.Sleep 200
    e = e + 200
  Loop
  WScript.Sleep 600
End Sub

Function SafeText(sess, id)
  On Error Resume Next
  Err.Clear
  SafeText = Clean(sess.FindById(id).Text)
  If Err.Number <> 0 Then SafeText = "" : Err.Clear
  On Error GoTo 0
End Function

Function Clean(v)
  Dim t
  t = CStr(v)
  t = Replace(t, vbCr, " ")
  t = Replace(t, vbLf, " ")
  t = Replace(t, vbTab, " ")
  t = Replace(t, "|", "/")
  Clean = t
End Function

Sub Bail(prefix, code)
  WScript.Echo prefix & " " & Hex(Err.Number) & " " & Err.Description
  WScript.Quit code
End Sub
