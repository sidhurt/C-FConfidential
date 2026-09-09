Option Explicit
' Read-only SAP GUI Scripting. Never saves, activates, executes ABAP, or dismisses dialogs.
' Usage: cscript //nologo sap_class_read.vbs SID CLIENT CLASS [METHOD]
Dim app, con, candidate, sess, i, j, sid, client, cls, method, elapsed
Dim tid, tbl, pos, r, name, found, ed, seen
If WScript.Arguments.Count < 3 Then WScript.Quit 2
sid = UCase(WScript.Arguments(0)) : client = WScript.Arguments(1)
cls = UCase(WScript.Arguments(2)) : method = ""
If WScript.Arguments.Count > 3 Then method = UCase(WScript.Arguments(3))
Set sess = Nothing
Set app = GetObject("SAPGUI").GetScriptingEngine
For i = 0 To app.Children.Count - 1
  Set con = app.Children(CLng(i))
  For j = 0 To con.Children.Count - 1
    Set candidate = con.Children(CLng(j))
    If candidate.Info.SystemName = sid And candidate.Info.Client = client Then
      If Not sess Is Nothing Then WScript.Echo "ABORT|AMBIGUOUS_SESSION" : WScript.Quit 9
      Set sess = candidate
    End If
  Next
Next
If sess Is Nothing Then WScript.Echo "ABORT|SESSION_NOT_FOUND" : WScript.Quit 9
Ready
WScript.Echo "SESSION|" & sid & "|" & client & "|" & sess.Info.User
sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE24"
sess.FindById("wnd[0]").SendVKey 0
Ready
sess.FindById("wnd[0]/usr/ctxtSEOCLASS-CLSNAME").Text = cls
sess.FindById("wnd[0]/mbar/menu[0]/menu[2]").Select
Ready
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "STATUS|" & sess.FindById("wnd[0]/sbar").Text
sess.FindById("wnd[0]/usr/tabsCTS/tabpTAB_MTD").Select
Ready
tid = "wnd[0]/usr/tabsCTS/tabpTAB_MTD/ssubCSS:SAPLSEOD:0253/tblSAPLSEODMC"
Set tbl = sess.FindById(tid)
Set seen = CreateObject("Scripting.Dictionary")
pos = 0 : found = False
Do
  tbl.VerticalScrollbar.Position = pos
  Ready
  Set tbl = sess.FindById(tid)
  For r = 0 To tbl.VisibleRowCount - 1
    name = Trim(tbl.GetCell(CLng(r), CLng(0)).Text)
    If Len(name) > 0 Then
      If Not seen.Exists(name) Then
        seen.Add name, True
        If method = "" Then WScript.Echo "METHOD|" & name
      End If
      If method <> "" And UCase(name) = method Then
        tbl.GetCell(CLng(r), CLng(0)).SetFocus
        found = True
        Exit Do
      End If
    End If
  Next
  pos = pos + tbl.VisibleRowCount
Loop While pos <= tbl.VerticalScrollbar.Maximum
If method = "" Then WScript.Echo "COUNT|" & seen.Count : WScript.Quit 0
If Not found Then WScript.Echo "ABORT|METHOD_NOT_FOUND|" & method : WScript.Quit 11
sess.FindById("wnd[0]/usr/tabsCTS/tabpTAB_MTD/ssubCSS:SAPLSEOD:0253/btnPUSH_EDITOR").Press
Ready
Set ed = Nothing
FindEditor sess.FindById("wnd[0]/usr")
If ed Is Nothing Then WScript.Echo "ABORT|NO_EDITOR" : WScript.Quit 12
WScript.Echo "SOURCE_BEGIN|" & cls & "|" & method
If ed.SubType = "AbapEditor" Then
  For i = 1 To ed.GetLineCount()
    WScript.Echo ed.GetLineText(CLng(i))
  Next
Else
  WScript.Echo ed.Text
End If
WScript.Echo "SOURCE_END"

Sub Ready()
  elapsed = 0
  Do While sess.Busy
    If elapsed >= 30000 Then WScript.Echo "ABORT|BUSY_TIMEOUT" : WScript.Quit 10
    WScript.Sleep 100 : elapsed = elapsed + 100
  Loop
  WScript.Sleep 250
  If sess.Children.Count > 1 Then
    WScript.Echo "ABORT|DIALOG|" & sess.FindById("wnd[1]").Text
    WScript.Quit 10
  End If
End Sub

Sub FindEditor(node)
  Dim ty, st, n, child, container
  ty = "" : st = "" : container = False
  On Error Resume Next
  ty = node.Type : st = node.SubType : container = node.ContainerType
  On Error GoTo 0
  If ty = "GuiTextedit" Or st = "TextEdit" Or st = "AbapEditor" Then Set ed = node : Exit Sub
  If container Then
    For n = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(n))
      If ed Is Nothing Then FindEditor child
    Next
  End If
End Sub
