Option Explicit
' READ-ONLY: open SE16 for a table in QS4/700 and list the selection-screen input
' field ids together with the label text immediately to their left, so a filter can
' be targeted by name instead of guessed positionally. Executes nothing.

Dim sapGuiAuto, app, sess, elapsed, tbl, i, j, conn, s, found, u, k, ch
Dim labels, ids, id, inner, cpos, colS, rowS, col, row

If WScript.Arguments.Count < 1 Then WScript.Echo "USAGE|qs4_se16_fields.vbs <TABLE>" : WScript.Quit 1
tbl = UCase(WScript.Arguments(0))

Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
found = False
For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set s = conn.Children(CLng(j))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then
      Set sess = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT|NO_QS4_700_SESSION" : WScript.Quit 9

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 40000
AcceptFieldSelectionDialog
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = tbl
sess.FindById("wnd[0]").SendVKey 0
Ready 60000
AcceptFieldSelectionDialog

WScript.Echo "TABLE|" & tbl
WScript.Echo "SCREEN|" & sess.FindById("wnd[0]").Text

' Collect labels by (row,col) so each input can be paired with its caption.
Set labels = CreateObject("Scripting.Dictionary")
Set u = sess.FindById("wnd[0]/usr")
For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If ch.Type = "GuiLabel" Then
    id = ch.Id
    inner = ExtractBracket(id)
    cpos = InStr(inner, ",")
    If cpos > 0 Then
      colS = Left(inner, cpos - 1) : rowS = Mid(inner, cpos + 1)
      If IsNumeric(colS) And IsNumeric(rowS) Then
        If Not labels.Exists(CLng(rowS)) Then labels.Add CLng(rowS), ch.Text
      End If
    End If
  End If
  Err.Clear
  On Error GoTo 0
Next

For k = 0 To u.Children.Count - 1
  Set ch = u.Children.Item(CLng(k))
  On Error Resume Next
  If ch.Type = "GuiTextField" Or ch.Type = "GuiCTextField" Then
    id = ch.Id
    Dim shortId
    shortId = Replace(id, "/app/con[0]/ses[0]/wnd[0]/usr/", "")
    shortId = Replace(shortId, "/app/con[1]/ses[0]/wnd[0]/usr/", "")
    inner = ExtractBracket(id)
    cpos = InStr(inner, ",")
    Dim cap
    cap = ""
    If cpos > 0 Then
      rowS = Mid(inner, cpos + 1)
      If IsNumeric(rowS) Then
        If labels.Exists(CLng(rowS)) Then cap = labels.Item(CLng(rowS))
      End If
    End If
    If InStr(shortId, "-LOW") > 0 Or InStr(shortId, "MAX_SEL") > 0 Then
      WScript.Echo "FIELD|" & shortId & "|label='" & cap & "'|value='" & ch.Text & "'"
    End If
  End If
  Err.Clear
  On Error GoTo 0
Next

Function ExtractBracket(s2)
  Dim a, b
  ExtractBracket = ""
  a = InStrRev(s2, "[") : b = InStrRev(s2, "]")
  If a > 0 And b > a Then ExtractBracket = Mid(s2, a + 1, b - a - 1)
End Function

Sub AcceptFieldSelectionDialog()
  Do While sess.Children.Count > 1
    If sess.FindById("wnd[1]").Text <> "Select Fields for Selection" Then Exit Sub
    WScript.Echo "DIALOG|accepted SE16 field-selection prompt"
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
