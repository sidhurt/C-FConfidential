Option Explicit
' READ-ONLY: read the SE24 Methods table control, scrolling through all rows.
Dim app, conn, s, sess, found, i, j, tbl, tid, rows, vis, pos, r, c, cell, line, nm, seen, elapsed
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

tid = "wnd[0]/usr/tabsCTS/tabpTAB_MTD/ssubCSS:SAPLSEOD:0253/tblSAPLSEODMC"
Set tbl = sess.FindById(tid)
rows = tbl.RowCount
vis  = tbl.VisibleRowCount
WScript.Echo "TABLE|rows(total)=" & tbl.VerticalScrollbar.Maximum + 1 & "|visibleRows=" & vis
Set seen = CreateObject("Scripting.Dictionary")

pos = 0
Do
  On Error Resume Next
  tbl.VerticalScrollbar.Position = pos
  Ready 20000
  Set tbl = sess.FindById(tid)
  Err.Clear
  On Error GoTo 0
  For r = 0 To tbl.VisibleRowCount - 1
    line = ""
    nm = ""
    For c = 0 To 6
      cell = "@ERR@"
      On Error Resume Next
      cell = tbl.GetCell(CLng(r), CLng(c)).Text
      Err.Clear
      On Error GoTo 0
      If cell = "@ERR@" Then
        line = line & vbTab
      Else
        If c = 0 Then nm = cell
        line = line & cell & vbTab
      End If
    Next
    If Len(Trim(nm)) > 0 Then
      If Not seen.Exists(nm) Then
        seen.Add nm, 1
        WScript.Echo "M|" & line
      End If
    End If
  Next
  pos = pos + tbl.VisibleRowCount
Loop While pos <= tbl.VerticalScrollbar.Maximum
WScript.Echo "TOTAL_DISTINCT|" & seen.Count

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 150
    elapsed = elapsed + 150
  Loop
  WScript.Sleep 400
End Sub
