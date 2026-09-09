Option Explicit
' STRICTLY READ-ONLY SE16 reader for DS4 client 200.
' Locates the DS4/200 session by system name, never by index, and refuses anything else.
' The only SAP interaction is: /nSE16, enter table, optional selection values, F8 (display).
' It never posts, never changes, and never closes a modal other than the benign
' SE16 "Select Fields for Selection" prompt.
'
' Usage: cscript //nologo ds4_se16_read.vbs <TABLE> <MAXROWS> [selFieldId=VALUE ...]

Dim sapGuiAuto, app, sess, elapsed
Dim tbl, maxRows, i, j, arg, eq, fid, fval, conn, s, found

If WScript.Arguments.Count < 2 Then
  WScript.Echo "USAGE|ds4_se16_read.vbs <TABLE> <MAXROWS> [selFieldId=VALUE ...]"
  WScript.Quit 1
End If
tbl     = UCase(WScript.Arguments(0))
maxRows = WScript.Arguments(1)

Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine

found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then
      Set sess = s
      found = True
      WScript.Echo "SESSION|DS4/200 located at connection[" & i & "] session[" & j & "]|user=" & s.Info.User
      Exit For
    End If
  Next
  If found Then Exit For
Next

If Not found Then
  WScript.Echo "ABORT|NO_DS4_200_SESSION"
  WScript.Quit 9
End If

If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text & "|left open, not dismissed"
  WScript.Quit 10
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
AcceptFieldSelectionDialog

sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
AcceptFieldSelectionDialog
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_ON_TABLE_OPEN|" & sess.FindById("wnd[1]").Text
  WScript.Quit 12
End If

For i = 2 To WScript.Arguments.Count - 1
  arg = WScript.Arguments(i)
  eq = InStr(arg, "=")
  If eq > 1 Then
    fid  = Left(arg, eq - 1)
    fval = Mid(arg, eq + 1)
    On Error Resume Next
    sess.FindById("wnd[0]/usr/" & fid).Text = fval
    If Err.Number <> 0 Then
      WScript.Echo "SELFIELD_ERR|" & fid & "|" & Err.Description
      Err.Clear
    Else
      WScript.Echo "SELFIELD|" & fid & "=" & fval
    End If
    On Error GoTo 0
  End If
Next

On Error Resume Next
sess.FindById("wnd[0]/usr/txtMAX_SEL").Text = maxRows
Err.Clear
On Error GoTo 0

sess.FindById("wnd[0]").SendVKey 8
Ready 240000
AcceptFieldSelectionDialog
If sess.Children.Count > 1 Then
  WScript.Echo "MODAL_AFTER_EXECUTE|" & sess.FindById("wnd[1]").Text & "|left open, not dismissed"
  WScript.Quit 13
End If

WScript.Echo "TABLE|" & tbl
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text
DumpList

' DS4 renders the SE16 result as an ALV grid rather than a classic list.
' Try the grid first; fall back to the positional label reader.
Function DumpAlv()
  Dim g, cols, r, c, line, n, shown
  DumpAlv = False
  Set g = FindGrid(sess.FindById("wnd[0]/usr"), 0)
  If g Is Nothing Then Exit Function

  Set cols = g.ColumnOrder
  WScript.Echo "ALV|rows=" & g.RowCount & "|cols=" & cols.Count
  line = ""
  For c = 0 To cols.Count - 1
    line = line & cols(c) & vbTab
  Next
  WScript.Echo "HDR|" & line

  shown = g.VisibleRowCount
  For r = 0 To g.RowCount - 1
    If r > 200 Then Exit For
    ' page the grid so lazily-loaded rows are materialised before reading
    If shown > 0 And (r Mod shown) = 0 Then
      On Error Resume Next
      g.FirstVisibleRow = r
      Err.Clear
      On Error GoTo 0
    End If
    line = ""
    For c = 0 To cols.Count - 1
      Dim v
      v = ""
      On Error Resume Next
      v = g.GetCellValue(CLng(r), cols(c))
      Err.Clear
      On Error GoTo 0
      line = line & v & vbTab
    Next
    WScript.Echo "ROW" & r & "|" & line
  Next
  DumpAlv = True
End Function

Sub DumpList()
  Dim u, k, ch, id, inner, cpos, colS, rowS, col, row, cellCount
  If DumpAlv() Then Exit Sub
  Dim rowsDict, n, sortedRows, m, colDict, sortedCols, c, line, t
  Set rowsDict = CreateObject("Scripting.Dictionary")
  Set u = sess.FindById("wnd[0]/usr")
  cellCount = 0
  For k = 0 To u.Children.Count - 1
    Set ch = u.Children.Item(CLng(k))
    On Error Resume Next
    id = ch.Id
    If Err.Number <> 0 Then Err.Clear
    On Error GoTo 0
    inner = ExtractBracket(id)
    If Len(inner) > 0 Then
      cpos = InStr(inner, ",")
      If cpos > 0 Then
        colS = Left(inner, cpos - 1)
        rowS = Mid(inner, cpos + 1)
        If IsNumeric(colS) And IsNumeric(rowS) Then
          col = CLng(colS) : row = CLng(rowS)
          t = ""
          On Error Resume Next
          t = ch.Text
          Err.Clear
          On Error GoTo 0
          If Not rowsDict.Exists(row) Then rowsDict.Add row, CreateObject("Scripting.Dictionary")
          If Not rowsDict.Item(row).Exists(col) Then
            rowsDict.Item(row).Add col, t
            cellCount = cellCount + 1
          End If
        End If
      End If
    End If
  Next
  WScript.Echo "CELLS|" & cellCount
  If rowsDict.Count = 0 Then Exit Sub
  sortedRows = SortNumeric(rowsDict.Keys)
  For n = 0 To UBound(sortedRows)
    row = sortedRows(n)
    Set colDict = rowsDict.Item(row)
    sortedCols = SortNumeric(colDict.Keys)
    line = ""
    For m = 0 To UBound(sortedCols)
      c = sortedCols(m)
      line = line & "[" & c & "]" & colDict.Item(c) & vbTab
    Next
    If Len(Trim(Replace(Replace(line, vbTab, ""), " ", ""))) > 0 Then
      WScript.Echo "R" & row & "|" & line
    End If
  Next
End Sub

' Recursively locate the ALV GridView shell anywhere under the user area.
Function FindGrid(node, depth)
  Dim k, child, res
  Set FindGrid = Nothing
  If depth > 8 Then Exit Function
  On Error Resume Next
  If node.Type = "GuiShell" Then
    If node.SubType = "GridView" Then
      Set FindGrid = node
      Exit Function
    End If
  End If
  If node.ContainerType = True Then
    For k = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(k))
      Set res = FindGrid(child, depth + 1)
      If Not res Is Nothing Then
        Set FindGrid = res
        Exit Function
      End If
    Next
  End If
  On Error GoTo 0
End Function

Function ExtractBracket(s2)
  Dim a, b
  ExtractBracket = ""
  a = InStrRev(s2, "[")
  b = InStrRev(s2, "]")
  If a > 0 And b > a Then ExtractBracket = Mid(s2, a + 1, b - a - 1)
End Function

Function SortNumeric(arr)
  Dim out, i2, j2, tmp2
  out = arr
  For i2 = 0 To UBound(out) - 1
    For j2 = i2 + 1 To UBound(out)
      If CLng(out(i2)) > CLng(out(j2)) Then
        tmp2 = out(i2) : out(i2) = out(j2) : out(j2) = tmp2
      End If
    Next
  Next
  SortNumeric = out
End Function

Sub AcceptFieldSelectionDialog()
  Do While sess.Children.Count > 1
    If sess.FindById("wnd[1]").Text <> "Select Fields for Selection" Then Exit Sub
    WScript.Echo "DIALOG|accepted SE16 field-selection prompt (read-only, >40 fields)"
    sess.FindById("wnd[1]").SendVKey 0
    Ready 30000
  Loop
End Sub

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 600
End Sub
