Option Explicit
' READ-ONLY QS4/700 SE16N reader. Locates selection fields BY NAME (no hardcoded rows).
' USAGE: qs4_se16n_read.vbs <TABLE> <MAXROWS> FIELD=LOW [FIELD=LOW..HIGH] ...
' Executes a SELECT only. Never enters SE16N maintenance/edit mode.
Dim app, conn, s, sess, found, i, j, tbl, maxRows, elapsed
Dim tcId, tc, rowsMax, pos, r, fname, arg, eq, wantF, wantL, wantH, dd, k
Dim grid, c, rr, line, colName, v, setCount

If WScript.Arguments.Count < 2 Then WScript.Echo "USAGE|TABLE MAXROWS FIELD=LOW[..HIGH] ..." : WScript.Quit 1
tbl = UCase(CStr(WScript.Arguments(0)))
maxRows = CStr(WScript.Arguments(1))

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
WScript.Echo "SESSION|" & sess.Info.SystemName & "/" & sess.Info.Client & "|User=" & sess.Info.User & "|Before=" & sess.Info.Transaction
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_BEFORE|" & SafeText("wnd[1]") : WScript.Quit 10

sess.StartTransaction "SE16N"
Ready 20000
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_AFTER_NAV|" & SafeText("wnd[1]") : WScript.Quit 11
If sess.Info.Transaction <> "SE16N" Then WScript.Echo "ABORT|TCODE_NOT_REACHED|" & sess.Info.Transaction : WScript.Quit 11

sess.FindById("wnd[0]/usr/ctxtGD-TAB").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 20000
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_AFTER_TABLE|" & SafeText("wnd[1]") : WScript.Quit 12

' collect requested filters into a dictionary
Set dd = CreateObject("Scripting.Dictionary")
For i = 2 To WScript.Arguments.Count - 1
  arg = CStr(WScript.Arguments(i))
  eq = InStr(arg, "=")
  If eq > 1 Then dd.Add UCase(Left(arg, eq - 1)), Mid(arg, eq + 1)
Next

tcId = "wnd[0]/usr/tblSAPLSE16NSELFIELDS_TC"
setCount = 0
pos = 0
Do
  On Error Resume Next
  Set tc = sess.FindById(tcId)
  If Err.Number <> 0 Then WScript.Echo "ABORT|NO_SELFIELDS_TC|" & Err.Description : WScript.Quit 13
  tc.VerticalScrollbar.Position = pos
  Ready 15000
  Set tc = sess.FindById(tcId)
  rowsMax = tc.VerticalScrollbar.Maximum
  Err.Clear
  On Error GoTo 0
  For r = 0 To tc.VisibleRowCount - 1
    fname = ""
    On Error Resume Next
    fname = sess.FindById(tcId & "/txtGS_SELFIELDS-FIELD[1," & r & "]").Text
    If Err.Number <> 0 Then Err.Clear : fname = ""
    On Error GoTo 0
    fname = UCase(Trim(fname))
    If Len(fname) > 0 Then
      If dd.Exists(fname) Then
        wantL = dd(fname) : wantH = ""
        k = InStr(wantL, "..")
        If k > 0 Then wantH = Mid(wantL, k + 2) : wantL = Left(wantL, k - 1)
        On Error Resume Next
        sess.FindById(tcId & "/ctxtGS_SELFIELDS-LOW[2," & r & "]").Text = wantL
        If Err.Number <> 0 Then Err.Clear : sess.FindById(tcId & "/txtGS_SELFIELDS-LOW[2," & r & "]").Text = wantL
        Err.Clear
        If Len(wantH) > 0 Then
          sess.FindById(tcId & "/ctxtGS_SELFIELDS-HIGH[3," & r & "]").Text = wantH
          If Err.Number <> 0 Then Err.Clear : sess.FindById(tcId & "/txtGS_SELFIELDS-HIGH[3," & r & "]").Text = wantH
          Err.Clear
        End If
        On Error GoTo 0
        WScript.Echo "FILTER|" & fname & "=" & wantL & IIfS(Len(wantH) > 0, ".." & wantH, "")
        setCount = setCount + 1
        dd.Remove fname
      End If
    End If
  Next
  pos = pos + tc.VisibleRowCount
Loop While pos <= rowsMax And dd.Count > 0

If dd.Count > 0 Then
  For Each k In dd.Keys
    WScript.Echo "WARN|FIELD_NOT_FOUND|" & k
  Next
End If

On Error Resume Next
sess.FindById("wnd[0]/usr/txtMAX_SEL").Text = maxRows
Err.Clear
sess.FindById("wnd[0]/usr/ctxtGD-MAX_LINES").Text = maxRows
Err.Clear
On Error GoTo 0

sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
Ready 60000
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_AFTER_EXEC|" & SafeText("wnd[1]") : WScript.Quit 14

WScript.Echo "RESULT|Table=" & tbl & "|Title=" & Clean(SafeText("wnd[0]")) & "|SBAR=" & Clean(SafeText("wnd[0]/sbar"))
On Error Resume Next
Set grid = sess.FindById("wnd[0]/usr/cntlRESULT_LIST/shellcont/shell")
If Err.Number <> 0 Then WScript.Echo "NO_GRID|" & Err.Description : Err.Clear : WScript.Quit 0
On Error GoTo 0
WScript.Echo "GRID|ROWS=" & grid.RowCount & "|COLS=" & grid.ColumnCount
line = "COLS"
For c = 0 To grid.ColumnCount - 1
  line = line & "|" & grid.ColumnOrder(CLng(c))
Next
WScript.Echo line
For rr = 0 To grid.RowCount - 1
  If rr > 199 Then WScript.Echo "TRUNCATED_AT_200" : Exit For
  If grid.VisibleRowCount > 0 And (rr Mod grid.VisibleRowCount) = 0 Then
    On Error Resume Next : grid.FirstVisibleRow = rr : Err.Clear : On Error GoTo 0
  End If
  line = "ROW|" & rr
  For c = 0 To grid.ColumnCount - 1
    colName = grid.ColumnOrder(CLng(c))
    v = "" : On Error Resume Next : v = grid.GetCellValue(CLng(rr), CStr(colName)) : Err.Clear : On Error GoTo 0
    line = line & "|" & colName & "=" & Clean(v)
  Next
  WScript.Echo line
Next

Function IIfS(cond, a, b)
  If cond Then IIfS = a Else IIfS = b
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
  WScript.Sleep 600
End Sub
