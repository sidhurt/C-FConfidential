Option Explicit
' READ-ONLY QS4/700: SE24 -> class Display -> Methods tab -> position on <METHOD>
' -> press Sourcecode -> dump the ABAP editor text to <OUTFILE>. Changes nothing.
' USAGE: qs4_se24_method_source.vbs <CLASS> <METHOD> <OUTFILE>
Dim app, conn, s, sess, found, i, j, cls, mtd, outf, elapsed
Dim tid, tbl, pos, r, nm, hitRow, hitPos, ed, fso, ts

cls  = UCase(WScript.Arguments(0))
mtd  = UCase(WScript.Arguments(1))
outf = WScript.Arguments(2)

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
CloseModals

' --- open class in Display ---
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE24"
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
sess.FindById("wnd[0]/usr/ctxtSEOCLASS-CLSNAME").Text = cls
Ready 5000
sess.FindById("wnd[0]/mbar/menu[0]/menu[2]").Select   ' Object type -> Display
Ready 120000
CloseModals

' --- Methods tab ---
On Error Resume Next
sess.FindById("wnd[0]/usr/tabsCTS/tabpTAB_MTD").Select
Ready 40000
Err.Clear
On Error GoTo 0

tid = "wnd[0]/usr/tabsCTS/tabpTAB_MTD/ssubCSS:SAPLSEOD:0253/tblSAPLSEODMC"
Set tbl = sess.FindById(tid)
hitRow = -1 : hitPos = -1
pos = 0
Do
  On Error Resume Next
  tbl.VerticalScrollbar.Position = pos
  Ready 20000
  Set tbl = sess.FindById(tid)
  Err.Clear
  On Error GoTo 0
  For r = 0 To tbl.VisibleRowCount - 1
    nm = ""
    On Error Resume Next
    nm = tbl.GetCell(CLng(r), CLng(0)).Text
    Err.Clear
    On Error GoTo 0
    If UCase(Trim(nm)) = mtd Then
      hitRow = r : hitPos = pos
      Exit Do
    End If
  Next
  pos = pos + tbl.VisibleRowCount
Loop While pos <= tbl.VerticalScrollbar.Maximum

If hitRow < 0 Then WScript.Echo "FAIL|METHOD_NOT_FOUND|" & mtd : WScript.Quit 11
WScript.Echo "FOUND|" & mtd & "|scrollPos=" & hitPos & "|visRow=" & hitRow

' --- put the cursor on that method, then press Sourcecode ---
Set tbl = sess.FindById(tid)
tbl.GetCell(CLng(hitRow), CLng(0)).SetFocus
Ready 20000
sess.FindById("wnd[0]/usr/tabsCTS/tabpTAB_MTD/ssubCSS:SAPLSEOD:0253/btnPUSH_EDITOR").Press
Ready 120000
CloseModals

WScript.Echo "EDITOR_SCREEN|" & sess.FindById("wnd[0]").Text & "|PROG=" & sess.Info.Program & "|SCR=" & sess.Info.ScreenNumber
WScript.Echo "SBAR|" & sess.FindById("wnd[0]/sbar").Text

Set ed = Nothing
FindEditor sess.FindById("wnd[0]/usr")
If ed Is Nothing Then WScript.Echo "FAIL|NO_EDITOR_CONTROL" : WScript.Quit 12

Set fso = CreateObject("Scripting.FileSystemObject")
Set ts = fso.CreateTextFile(outf, True, True)
ts.Write ed.Text
ts.Close
WScript.Echo "OK|" & mtd & "|chars=" & Len(ed.Text) & "|lines=" & (UBound(Split(ed.Text, vbCr)) + 1) & "|" & outf

Sub FindEditor(node)
  Dim n, child, ty, st
  On Error Resume Next
  ty = "" : ty = node.Type
  st = "" : st = node.SubType
  Err.Clear
  If ty = "GuiTextedit" Or st = "TextEdit" Then
    Set ed = node
    Exit Sub
  End If
  Dim isC : isC = False
  isC = node.ContainerType
  Err.Clear
  If isC = True Then
    For n = 0 To node.Children.Count - 1
      Set child = Nothing
      Set child = node.Children.Item(CLng(n))
      If Err.Number = 0 And Not child Is Nothing And ed Is Nothing Then FindEditor child
      Err.Clear
    Next
  End If
  On Error GoTo 0
End Sub

Sub CloseModals()
  Dim guard : guard = 0
  Do While sess.Children.Count > 1 And guard < 8
    sess.FindById("wnd[" & (sess.Children.Count - 1) & "]").SendVKey 12
    Ready 10000
    guard = guard + 1
  Loop
End Sub
Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200
    elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub
