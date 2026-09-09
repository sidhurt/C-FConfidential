Option Explicit
' BAPI_GOODSMVT_CREATE TEST RUN harness - QS4/700, read-only.
' Builds the delivery-referenced, no-PO payload and executes with TESTRUN = 'X'.
' Refuses to execute unless TESTRUN is verified as 'X'. No COMMIT is ever issued.
'
' Usage: bapi-testrun.vbs <DELIVERY> <ITEM> <PLANT> [MATERIAL] [QTY] [UOM] [SLOC]
'   Optional args left off are sent blank - that is the derivation test.

Dim SapGuiAuto, app, conn, sess
Dim deliv, item, plant, matnr, qty, uom, sloc, tr, r

If WScript.Arguments.Count < 3 Then
  WScript.Echo "ERR usage: <DELIVERY> <ITEM> <PLANT> [MATERIAL] [QTY] [UOM] [SLOC]"
  WScript.Quit 2
End If
deliv = WScript.Arguments(0)
item  = WScript.Arguments(1)
plant = WScript.Arguments(2)
' "-" means "send this field blank" (PowerShell cannot pass a true empty argument)
matnr = "" : qty = "" : uom = "" : sloc = ""
If WScript.Arguments.Count > 3 Then matnr = Blankable(WScript.Arguments(3))
If WScript.Arguments.Count > 4 Then qty   = Blankable(WScript.Arguments(4))
If WScript.Arguments.Count > 5 Then uom   = Blankable(WScript.Arguments(5))
If WScript.Arguments.Count > 6 Then sloc  = Blankable(WScript.Arguments(6))

Function Blankable(v)
  If Trim(v) = "-" Then Blankable = "" Else Blankable = v
End Function

Set SapGuiAuto = GetObject("SAPGUI")
Set app = SapGuiAuto.GetScriptingEngine
Set conn = app.Children(0)
Set sess = conn.Children(0)

If sess.Info.SystemName <> "QS4" Or sess.Info.Client <> "700" Then
  WScript.Echo "ABORT wrong system" : WScript.Quit 9
End If

' --- SE37 test screen ---
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
sess.FindById("wnd[0]").SendVKey 0 : WScript.Sleep 1500
sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = "BAPI_GOODSMVT_CREATE"
sess.FindById("wnd[0]").SendVKey 0 : WScript.Sleep 800
sess.FindById("wnd[0]").SendVKey 8 : WScript.Sleep 2500
WScript.Echo "SCREEN=" & sess.FindById("wnd[0]").Text

' --- TESTRUN first ---
sess.FindById("wnd[0]/usr/txt[34,11]").Text = "X"
WScript.Sleep 300

' --- GOODSMVT_CODE ---
sess.FindById("wnd[0]/usr/lbl[2,10]").SetFocus
sess.FindById("wnd[0]").SendVKey 2 : WScript.Sleep 1800
sess.FindById("wnd[0]/usr/txt[1,3]").Text = "01"
sess.FindById("wnd[0]").SendVKey 3 : WScript.Sleep 1500
WScript.Echo "GM_CODE set"

' --- GOODSMVT_HEADER ---
sess.FindById("wnd[0]/usr/lbl[2,9]").SetFocus
sess.FindById("wnd[0]").SendVKey 2 : WScript.Sleep 1800
sess.FindById("wnd[0]/usr/txt[1,3]").Text  = "02.09.2026"
sess.FindById("wnd[0]/usr/txt[12,3]").Text = "02.09.2026"
sess.FindById("wnd[0]/usr/txt[81,3]").Text = "CNF TESTRUN"
sess.FindById("wnd[0]").SendVKey 3 : WScript.Sleep 1500
WScript.Echo "HEADER set"

' --- GOODSMVT_ITEM ---
sess.FindById("wnd[0]/usr/lbl[2,18]").SetFocus
sess.FindById("wnd[0]").SendVKey 2 : WScript.Sleep 2000
If InStr(sess.FindById("wnd[0]").Text, "GOODSMVT_ITEM") = 0 Then
  WScript.Echo "ABORT not on item editor: " & sess.FindById("wnd[0]").Text : WScript.Quit 13
End If
sess.FindById("wnd[0]/tbar[1]/btn[19]").Press : WScript.Sleep 2000
If sess.Children.Count < 2 Then WScript.Echo "ABORT no single-entry modal" : WScript.Quit 14

SetRow 0,  6, plant, "PLANT"
SetRow 0,  9, "101", "MOVE_TYPE"
If matnr <> "" Then SetRow 0, 5, matnr, "MATERIAL"
If sloc  <> "" Then SetRow 0, 7, sloc,  "STGE_LOC"
If qty   <> "" Then SetRow 0, 18, qty,  "ENTRY_QNT"
If uom   <> "" Then SetRow 0, 19, uom,  "ENTRY_UOM"
If WScript.Arguments.Count > 7 Then
  If Trim(WScript.Arguments(7)) = "X" Then SetRow 68, 4, "X", "IND_PROPOSE_QUANX"
End If
SetRow 40,  7, "B",   "MVT_IND"
' 9th arg NOSEARCH: leave DELIV_NUMB_TO_SEARCH empty so the BAdI must fill it.
Dim skipSearch
skipSearch = False
If WScript.Arguments.Count > 8 Then
  If UCase(Trim(WScript.Arguments(8))) = "NOSEARCH" Then skipSearch = True
End If
If skipSearch Then
  WScript.Echo "  SKIP DELIV_NUMB_TO_SEARCH (left empty for BAdI)"
Else
  SetRow 68,  7, deliv, "DELIV_NUMB_TO_SEARCH"
End If
SetRow 104, 7, deliv, "DELIV_NUMB"
SetRow 104, 8, item,  "DELIV_ITEM"

' close modal, back to test screen
Dim g2
On Error Resume Next
If sess.Children.Count > 1 Then
  Err.Clear
  sess.FindById("wnd[1]/tbar[0]/btn[0]").Press
  If Err.Number <> 0 Then Err.Clear : sess.FindById("wnd[1]").SendVKey 0
  Err.Clear
End If
On Error GoTo 0
WScript.Sleep 1500

g2 = 0
Do While InStr(sess.FindById("wnd[0]").Text, "Test Function Module: Initial Screen") = 0 And g2 < 8
  On Error Resume Next
  Err.Clear
  If sess.Children.Count > 1 Then
    sess.FindById("wnd[1]").SendVKey 0
  Else
    sess.FindById("wnd[0]").SendVKey 3
  End If
  Err.Clear
  On Error GoTo 0
  WScript.Sleep 1500
  g2 = g2 + 1
Loop

' --- SAFETY GATE ---
tr = sess.FindById("wnd[0]/usr/txt[34,11]").Text
WScript.Echo "TESTRUN='" & tr & "'"
If UCase(Trim(tr)) <> "X" Then
  WScript.Echo "ABORT TESTRUN not X - refusing to execute" : WScript.Quit 12
End If
WScript.Echo "HEADER=" & sess.FindById("wnd[0]/usr/lbl[37,9]").Text
WScript.Echo "GM_CODE=" & sess.FindById("wnd[0]/usr/lbl[37,10]").Text
WScript.Echo "EXECUTING TEST RUN"

sess.FindById("wnd[0]").SendVKey 8 : WScript.Sleep 5000
WScript.Echo "RESULT=" & sess.FindById("wnd[0]").Text
If sess.Children.Count > 1 Then WScript.Echo "MODAL=" & sess.FindById("wnd[1]").Text
WScript.Echo "SBAR=" & sess.FindById("wnd[0]/sbar").Text

' dump the result screen labels so RETURN can be located
For r = 14 To 30
  On Error Resume Next
  Dim t1, t2
  Err.Clear
  t1 = sess.FindById("wnd[0]/usr/lbl[2," & r & "]").Text
  If Err.Number = 0 And Len(Trim(t1)) > 0 Then
    Err.Clear
    t2 = sess.FindById("wnd[0]/usr/lbl[37," & r & "]").Text
    WScript.Echo "  row " & r & "  " & t1 & "  |  " & Trim(t2)
  End If
  Err.Clear
  On Error GoTo 0
Next

Sub SetRow(vpos, row, val, name)
  On Error Resume Next
  Err.Clear
  sess.FindById("wnd[1]/usr").VerticalScrollbar.Position = vpos
  Err.Clear
  WScript.Sleep 900
  Dim lab
  lab = sess.FindById("wnd[1]/usr/lbl[12," & row & "]").Text
  If Err.Number <> 0 Then WScript.Echo "  FAIL locate " & name : Err.Clear : Exit Sub
  If InStr(UCase(lab), UCase(name)) = 0 Then
    WScript.Echo "  WARN row " & row & " at vpos " & vpos & " is '" & lab & "', expected " & name
  End If
  sess.FindById("wnd[1]/usr/txt[43," & row & "]").Text = val
  If Err.Number <> 0 Then
    WScript.Echo "  FAIL set " & name & ": " & Err.Description : Err.Clear
  Else
    WScript.Echo "  SET " & lab & " = '" & val & "'"
  End If
  On Error GoTo 0
End Sub
