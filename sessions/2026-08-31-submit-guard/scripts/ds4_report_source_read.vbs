Option Explicit
' READ-ONLY: open an executable/include in SE38 display mode and print context around a term.
' Usage: cscript //nologo ds4_report_source_context.vbs <PROGRAM> <TERM> [CONTEXT]

Dim app, sess, conn, s, i, j, found, prog, term, ctx, elapsed, ed, lines, n, a, b, k
If WScript.Arguments.Count < 2 Then WScript.Echo "USAGE|<PROGRAM>|<TERM>|[CONTEXT]" : WScript.Quit 1
prog = UCase(WScript.Arguments(0)) : term = UCase(WScript.Arguments(1)) : ctx = 8
If WScript.Arguments.Count > 2 Then ctx = CLng(WScript.Arguments(2))

Set app = GetObject("SAPGUI").GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then Set sess = s : found = True : Exit For
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_DS4_200" : WScript.Quit 9
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_OPEN|" & sess.FindById("wnd[1]").Text : WScript.Quit 10

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE38"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
sess.FindById("wnd[0]/usr/ctxtRS38M-PROGRAMM").Text = prog
sess.FindById("wnd[0]").SendVKey 7
Ready 90000
If sess.Children.Count > 1 Then WScript.Echo "MODAL|" & sess.FindById("wnd[1]").Text : WScript.Quit 11

Set ed = FindEditor(sess.FindById("wnd[0]/usr"), 0)
If ed Is Nothing Then WScript.Echo "NO_EDITOR|" & sess.FindById("wnd[0]").Text : WScript.Quit 12
WScript.Echo "SOURCE|system=DS4|client=200|program=" & prog & "|term=" & term
If ed.SubType = "AbapEditor" Then
  ReDim lines(ed.GetLineCount() - 1)
  For n = 1 To ed.GetLineCount()
    lines(n-1) = ed.GetLineText(CLng(n))
  Next
Else
  lines = Split(Replace(ed.Text, vbCrLf, vbLf), vbLf)
End If
For n = 0 To UBound(lines)
  If InStr(UCase(lines(n)), term) > 0 Then
    a = n - ctx : If a < 0 Then a = 0
    b = n + ctx : If b > UBound(lines) Then b = UBound(lines)
    WScript.Echo "HIT|line=" & (n + 1)
    For k = a To b
      WScript.Echo Right("000000" & CStr(k + 1), 6) & "|" & Clean(lines(k))
    Next
  End If
Next

Function FindEditor(node, depth)
  Dim kk, child, res, typ, subtyp
  Set FindEditor = Nothing
  If depth > 10 Then Exit Function
  On Error Resume Next
  typ = node.Type : subtyp = node.SubType
  If typ = "GuiTextEdit" Or (typ = "GuiShell" And (subtyp = "TextEdit" Or subtyp = "AbapEditor")) Then Set FindEditor = node : Exit Function
  If node.ContainerType = True Then
    For kk = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(kk))
      Set res = FindEditor(child, depth + 1)
      If Not res Is Nothing Then Set FindEditor = res : Exit Function
    Next
  End If
  Err.Clear
  On Error GoTo 0
End Function

Sub Ready(maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 800
End Sub

Function Clean(v)
  v = Replace(CStr(v), vbCr, " ")
  v = Replace(v, vbLf, " ")
  v = Replace(v, vbTab, "  ")
  v = Replace(v, "|", "/")
  Clean = v
End Function
