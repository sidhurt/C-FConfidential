Option Explicit
' READ-ONLY SE16 reader for DS4/200.
' Reconstructs the classic-list result by enumerating GuiLabel/GuiTextField
' positions from their control ids (lbl[col,row] / txt[col,row]).
'
' Usage: cscript //nologo se16_read_list.vbs <TABLE> <MAXROWS> [selFieldId=VALUE ...]
'   e.g. se16_read_list.vbs T161 50
'        se16_read_list.vbs MARD 30 ctxtI2-LOW=PLQ3
'
' Never closes a modal. Never writes to SAP. F8 on the SE16 selection screen is a read.

Dim sapGuiAuto, app, conn, sess, elapsed
Dim tbl, maxRows, i, arg, eq, fid, fval

If WScript.Arguments.Count < 2 Then
  WScript.Echo "USAGE|se16_read_list.vbs <TABLE> <MAXROWS> [selFieldId=VALUE ...]"
  WScript.Quit 1
End If
tbl     = UCase(WScript.Arguments(0))
maxRows = WScript.Arguments(1)

Set sapGuiAuto = GetObject("SAPGUI")
Set app  = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))

If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "ABORT|WRONG_SYSTEM_OR_CLIENT|" & sess.Info.SystemName & "/" & sess.Info.Client
  WScript.Quit 9
End If
AcceptFieldSelectionDialog
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text & "|left open, not dismissed"
  WScript.Quit 10
End If

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_ON_SE16_ENTRY|" & sess.FindById("wnd[1]").Text
  WScript.Quit 11
End If

sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
AcceptFieldSelectionDialog
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_ON_TABLE_OPEN|" & sess.FindById("wnd[1]").Text
  WScript.Quit 12
End If

' selection fields
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

' ---------------------------------------------------------------- helpers
Sub DumpList()
  Dim u, k, ch, id, inner, cpos, colS, rowS, col, row
  Dim maxRow, r, c, line, cellCount
  Dim cells()   ' cells(row, col) is impractical; use a dictionary of row -> text
  Dim rowsDict, colsDict, key

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
          col = CLng(colS)
          row = CLng(rowS)
          Dim t
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

  ' emit rows in ascending row order, cells in ascending column order
  Dim rowKeys, sortedRows, n, tmp
  rowKeys = rowsDict.Keys
  sortedRows = SortNumeric(rowKeys)

  For n = 0 To UBound(sortedRows)
    row = sortedRows(n)
    Dim colDict, colKeys, sortedCols, m
    Set colDict = rowsDict.Item(row)
    colKeys = colDict.Keys
    sortedCols = SortNumeric(colKeys)
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

Function ExtractBracket(s)
  Dim a, b
  ExtractBracket = ""
  a = InStrRev(s, "[")
  b = InStrRev(s, "]")
  If a > 0 And b > a Then ExtractBracket = Mid(s, a + 1, b - a - 1)
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

' Accepts ONLY the benign SE16 "Select Fields for Selection" prompt, which SAP raises
' when a table has more than 40 selectable fields. Matched by exact title; any other
' modal is left untouched for inspection. This is a read-only display prompt.
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
