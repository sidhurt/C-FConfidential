Option Explicit
' READ-ONLY. Dumps the rows of a GridView (id passed as arg 1, relative to the session)
' on the QS4/700 session. Reads cell values only; clicks nothing.
Dim app, conn, s, sess, ci, si, found, g, cols, r, c, line
Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For ci = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(ci))
  For si = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(si))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT no QS4/700 session" : WScript.Quit 9
Set g = sess.FindById(WScript.Arguments(0))
Set cols = g.ColumnOrder
line = ""
For c = 0 To cols.Count - 1 : line = line & cols(c) & vbTab : Next
WScript.Echo "HDR|" & line
For r = 0 To g.RowCount - 1
  line = ""
  For c = 0 To cols.Count - 1 : line = line & g.GetCellValue(CLng(r), cols(c)) & vbTab : Next
  WScript.Echo "ROW" & r & "|" & line
Next
