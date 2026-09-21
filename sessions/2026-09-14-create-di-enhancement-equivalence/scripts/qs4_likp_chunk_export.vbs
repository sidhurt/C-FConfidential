Option Explicit
' READ-ONLY. QS4/700 SE16 LIKP export in VBELN chunks, reduced layout, tab-delimited text.
' USAGE: qs4_likp_chunk_export.vbs <OUT_DIR> <FROM> <TO> <STEP> <COLS_CSV>
Dim fso, app, sess, found, i, j, s, conn, outDir, vFrom, vTo, stepN, cols, lo, hi, outFile, n, g, e, t0
Set fso = CreateObject("Scripting.FileSystemObject")
ExecuteGlobal fso.OpenTextFile(fso.GetParentFolderName(WScript.ScriptFullName) & "\layout_lib.vbs").ReadAll
outDir = WScript.Arguments(0) : vFrom = CDbl(WScript.Arguments(1)) : vTo = CDbl(WScript.Arguments(2)) : stepN = CDbl(WScript.Arguments(3)) : cols = WScript.Arguments(4)
Set app = GetObject("SAPGUI").GetScriptingEngine
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True
  Next
Next
If Not found Then WScript.Echo "ABORT|NO_QS4_700" : WScript.Quit 9
lo = vFrom
Do While lo <= vTo
  hi = lo + stepN - 1 : If hi > vTo Then hi = vTo
  outFile = "LIKP_" & CStr(lo) & "_" & CStr(hi) & ".txt"
  t0 = Timer
  If sess.Children.Count > 1 Then WScript.Echo "ABORT|POPUP|" & sess.FindById("wnd[1]").Text : WScript.Quit 10
  sess.StartTransaction "SE16" : W 30000
  sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = "LIKP"
  sess.FindById("wnd[0]").SendVKey 0 : W 30000
  sess.FindById("wnd[0]/usr/ctxtI1-LOW").Text = CStr(lo)
  sess.FindById("wnd[0]/usr/ctxtI1-HIGH").Text = CStr(hi)
  sess.FindById("wnd[0]/usr/txtMAX_SEL").Text = ""
  sess.FindById("wnd[0]").SendVKey 8 : W 1800000
  If sess.Children.Count > 1 Then WScript.Echo "ABORT|POPUP_AFTER_EXEC|" & sess.FindById("wnd[1]").Text : WScript.Quit 11
  On Error Resume Next
  Set g = Nothing
  Set g = sess.FindById("wnd[0]/usr/cntlGRID1/shellcont/shell")
  If Err.Number <> 0 Then
    Err.Clear : On Error GoTo 0
    WScript.Echo "CHUNK|" & lo & ".." & hi & "|NO_GRID|" & sess.FindById("wnd[0]/sbar").Text
  Else
    On Error GoTo 0
    n = ApplyLayout(sess, cols)
    If n < 1 Then WScript.Echo "ABORT|LAYOUT_FAILED|" & lo : WScript.Quit 12
    sess.FindById("wnd[0]/tbar[1]/btn[45]").Press : W 60000
    If sess.FindById("wnd[1]").Text <> "Save list in file..." Then WScript.Echo "ABORT|UNEXPECTED|" & sess.FindById("wnd[1]").Text : WScript.Quit 13
    sess.FindById("wnd[1]/usr/subSUBSCREEN_STEPLOOP:SAPLSPO5:0150/sub:SAPLSPO5:0150/radSPOPLI-SELFLAG[1,0]").Select
    sess.FindById("wnd[1]/tbar[0]/btn[0]").Press : W 60000
    If sess.FindById("wnd[1]").Text <> "Save File" Then WScript.Echo "ABORT|UNEXPECTED|" & sess.FindById("wnd[1]").Text : WScript.Quit 14
    sess.FindById("wnd[1]/usr/ctxtDY_PATH").Text = outDir
    sess.FindById("wnd[1]/usr/ctxtDY_FILENAME").Text = outFile
    sess.FindById("wnd[1]/usr/ctxtDY_FILE_ENCODING").Text = "4110"
    If fso.FileExists(outDir & "\" & outFile) Then
      sess.FindById("wnd[1]/tbar[0]/btn[11]").Press
    Else
      sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
    End If
    W 900000
    If sess.Children.Count > 1 Then WScript.Echo "ABORT|POPUP_AFTER_SAVE|" & sess.FindById("wnd[1]").Text : WScript.Quit 15
    WScript.Echo "CHUNK|" & lo & ".." & hi & "|rows=" & g.RowCount & "|" & sess.FindById("wnd[0]/sbar").Text & "|secs=" & Round(Timer - t0)
  End If
  lo = hi + 1
Loop
WScript.Echo "DONE"
Sub W(maxMs)
  Dim x : x = 0
  Do While sess.Busy And x < maxMs : WScript.Sleep 300 : x = x + 300 : Loop
  WScript.Sleep 700
End Sub
