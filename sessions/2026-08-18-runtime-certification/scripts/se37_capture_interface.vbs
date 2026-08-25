Option Explicit
' Read-only SE37 interface capture for one function module.
' Usage: cscript //nologo se37_capture_interface.vbs <FM> <OUT_TSV>
Dim sapGuiAuto, app, conn, sess, fm, outPath, elapsed, fso, out
If WScript.Arguments.Count < 2 Then WScript.Echo "USAGE|<FM>|<OUT_TSV>" : WScript.Quit 1
fm = UCase(WScript.Arguments(0))
outPath = WScript.Arguments(1)
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then
  WScript.Echo "REFUSED|" & sess.Info.SystemName & "/" & sess.Info.Client : WScript.Quit 9
End If
Set fso = CreateObject("Scripting.FileSystemObject")
Set out = fso.CreateTextFile(outPath, True, True)

OpenDisplay fm
out.WriteLine "RecordType" & vbTab & "FunctionModule" & vbTab & "Section" & vbTab & "Parameter" & vbTab & "TypeDeclaration" & vbTab & "AssociatedType" & vbTab & "DefaultValue" & vbTab & "Optional" & vbTab & "PassByValue" & vbTab & "ShortText" & vbTab & "Value"
CaptureAttributes
CaptureParameterTab "IMPORT", "IMPORT"
CaptureParameterTab "EXPORT", "EXPORT"
CaptureParameterTab "CHANGE", "CHANGING"
CaptureParameterTab "TABLES", "TABLES"
CaptureParameterTab "EXCEPT", "EXCEPTIONS"
out.Close
WScript.Echo "CAPTURED|" & fm & "|" & outPath

Sub OpenDisplay(name)
  sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE37"
  sess.FindById("wnd[0]").SendVKey 0
  Ready 30000
  sess.FindById("wnd[0]/usr/ctxtRS38L-NAME").Text = name
  sess.FindById("wnd[0]/usr/btnBUT3").Press
  Ready 40000
  If InStr(UCase(sess.FindById("wnd[0]").Text), name) = 0 Then
    out.Close : WScript.Echo "OPEN_FAILED|" & name & "|" & sess.FindById("wnd[0]").Text : WScript.Quit 3
  End If
End Sub

Sub CaptureAttributes()
  Dim base, remote, normal, updateMod, released
  sess.FindById("wnd[0]/usr/tabsFUNC_TAB_STRIP/tabpHEADER").Select
  Ready 12000
  base = "wnd[0]/usr/tabsFUNC_TAB_STRIP/tabpHEADER/ssubSCREEN_HEADER:SAPLSFUNCTION_BUILDER:3030/"
  remote = BoolMark(SafeSelected(base & "radRS38L-REMOTE"))
  normal = BoolMark(SafeSelected(base & "radRS38L-NORMAL"))
  updateMod = BoolMark(SafeSelected(base & "radRS38L-VERBUCHER"))
  released = SafeText(base & "txtHEADER-FREIGTEXT")
  WriteAttr "System", sess.Info.SystemName
  WriteAttr "Client", sess.Info.Client
  WriteAttr "User", sess.Info.User
  WriteAttr "ActiveStatus", SafeText("wnd[0]/usr/txtHEADER-FBFOOTLINE")
  WriteAttr "FunctionGroup", SafeText(base & "txtHEADER-AREA")
  WriteAttr "FunctionGroupText", SafeText(base & "txtHEADER-AREAT")
  WriteAttr "ShortText", SafeText(base & "txtTFTIT-STEXT")
  WriteAttr "RegularFunctionModule", normal
  WriteAttr "RemoteEnabled", remote
  WriteAttr "UpdateModule", updateMod
  WriteAttr "ReleaseStatus", released
  WriteAttr "Package", SafeText(base & "txtTADIR-DEVCLASS")
  WriteAttr "Program", SafeText(base & "txtHEADER-PROGNAME")
  WriteAttr "Include", SafeText(base & "txtHEADER-INCLUDE")
  WriteAttr "ChangedOn", SafeText(base & "txtHEADER-FBTRDIR-UDAT")
End Sub

Sub WriteAttr(name, value)
  out.WriteLine "ATTRIBUTE" & vbTab & fm & vbTab & "ATTRIBUTES" & vbTab & name & vbTab & "" & vbTab & "" & vbTab & "" & vbTab & "" & vbTab & "" & vbTab & "" & vbTab & Clean(value)
End Sub

Sub CaptureParameterTab(tabId, sectionName)
  Dim tabPath, table, node
  tabPath = "wnd[0]/usr/tabsFUNC_TAB_STRIP/tabp" & tabId
  On Error Resume Next
  Err.Clear
  sess.FindById(tabPath).Select
  If Err.Number <> 0 Then Err.Clear : On Error GoTo 0 : Exit Sub
  On Error GoTo 0
  Ready 10000
  Set table = FindTable(sess.FindById(tabPath), 0)
  If table Is Nothing Then Exit Sub
  DumpVisibleTable table, sectionName
End Sub

Sub DumpVisibleTable(table, sectionName)
  Dim r, vis, pos, maxPos, nextPos, logicalRow, rowKey, tableId
  Dim param, typeDecl, assocType, defVal, optionalMark, passVal, shortText, seen
  Set seen = CreateObject("Scripting.Dictionary")
  tableId = table.Id
  vis = table.VisibleRowCount
  If vis < 1 Then vis = 22
  On Error Resume Next
  pos = table.VerticalScrollbar.Position
  maxPos = table.VerticalScrollbar.Maximum
  If Err.Number <> 0 Then Err.Clear : pos = 0 : maxPos = 0
  On Error GoTo 0
  pos = 0
  Do
    On Error Resume Next
    table.VerticalScrollbar.Position = pos
    Err.Clear
    On Error GoTo 0
    Ready 5000
    For r = 0 To vis - 1
      logicalRow = CLng(pos) + CLng(r)
      If sectionName = "EXCEPTIONS" Then
        param = FirstCell(tableId, "txtRSFBEXC-EXCEPTION[0," & r & "]", "ctxtRSFBEXC-EXCEPTION[0," & r & "]")
        shortText = FirstCell(tableId, "txtRSFBEXC-STEXT[1," & r & "]", "txtRSFBPARA-STEXT[1," & r & "]")
        typeDecl = "" : assocType = "" : defVal = "" : optionalMark = "" : passVal = ""
      ElseIf sectionName = "TABLES" Then
        param = FirstCell(tableId, "txtRSFBPARA-PARAMETER[0," & r & "]", "ctxtRSFBPARA-PARAMETER[0," & r & "]")
        typeDecl = FirstCell(tableId, "ctxtRSFBPARA-TYPEFIELD[1," & r & "]", "txtRSFBPARA-TYPEFIELD[1," & r & "]")
        assocType = FirstCell(tableId, "ctxtRSFBPARA-STRUCTURE[2," & r & "]", "txtRSFBPARA-STRUCTURE[2," & r & "]")
        defVal = ""
        optionalMark = CheckCell(tableId, "chkRSFBPARA-OPTIONAL[3," & r & "]")
        passVal = ""
        shortText = FirstCell(tableId, "txtRSFBPARA-STEXT[4," & r & "]", "ctxtRSFBPARA-STEXT[4," & r & "]")
      Else
        param = FirstCell(tableId, "txtRSFBPARA-PARAMETER[0," & r & "]", "ctxtRSFBPARA-PARAMETER[0," & r & "]")
        typeDecl = FirstCell(tableId, "ctxtRSFBPARA-TYPEFIELD[1," & r & "]", "txtRSFBPARA-TYPEFIELD[1," & r & "]")
        assocType = FirstCell(tableId, "ctxtRSFBPARA-STRUCTURE[2," & r & "]", "txtRSFBPARA-STRUCTURE[2," & r & "]")
        defVal = FirstCell(tableId, "txtRSFBPARA-DEFAULTVAL[3," & r & "]", "ctxtRSFBPARA-DEFAULTVAL[3," & r & "]")
        optionalMark = CheckCell(tableId, "chkRSFBPARA-OPTIONAL[4," & r & "]")
        passVal = CheckCell(tableId, "chkRSFBPARA-VALUE[5," & r & "]")
        shortText = FirstCell(tableId, "txtRSFBPARA-STEXT[6," & r & "]", "ctxtRSFBPARA-STEXT[6," & r & "]")
      End If
      rowKey = sectionName & "|" & logicalRow & "|" & param
      If Len(param) > 0 And Not seen.Exists(rowKey) Then
        seen.Add rowKey, True
        out.WriteLine "PARAMETER" & vbTab & fm & vbTab & sectionName & vbTab & Clean(param) & vbTab & Clean(typeDecl) & vbTab & Clean(assocType) & vbTab & Clean(defVal) & vbTab & Clean(optionalMark) & vbTab & Clean(passVal) & vbTab & Clean(shortText) & vbTab & ""
      End If
    Next
    nextPos = pos + vis
    If nextPos > maxPos Then nextPos = maxPos
    If nextPos <= pos Then Exit Do
    pos = nextPos
  Loop
End Sub

Function FirstCell(tableId, suffix1, suffix2)
  FirstCell = CellText(tableId & "/" & suffix1)
  If Len(FirstCell) = 0 And Len(suffix2) > 0 Then FirstCell = CellText(tableId & "/" & suffix2)
End Function

Function CellText(id)
  On Error Resume Next
  CellText = Clean(sess.FindById(id).Text)
  If Err.Number <> 0 Then Err.Clear : CellText = ""
  On Error GoTo 0
End Function

Function CheckCell(tableId, suffix)
  On Error Resume Next
  CheckCell = ""
  If sess.FindById(tableId & "/" & suffix).Selected Then CheckCell = "X"
  If Err.Number <> 0 Then Err.Clear : CheckCell = ""
  On Error GoTo 0
End Function

Function FindTable(node, depth)
  Dim k, child, found, t
  Set FindTable = Nothing
  If depth > 7 Then Exit Function
  On Error Resume Next
  t = node.Type
  On Error GoTo 0
  If t = "GuiTableControl" Then Set FindTable = node : Exit Function
  On Error Resume Next
  For k = 0 To node.Children.Count - 1
    Set child = node.Children.Item(CLng(k))
    Set found = FindTable(child, depth + 1)
    If Not (found Is Nothing) Then Set FindTable = found : Exit Function
  Next
  On Error GoTo 0
End Function

Function SafeNodeValue(node)
  Dim t, v
  v = ""
  On Error Resume Next
  t = node.Type
  If t = "GuiCheckBox" Or t = "GuiRadioButton" Then
    If node.Selected Then v = "X"
  Else
    v = node.Text
  End If
  If Err.Number <> 0 Then Err.Clear : v = ""
  On Error GoTo 0
  SafeNodeValue = Clean(v)
End Function

Function SafeText(id)
  On Error Resume Next
  SafeText = Clean(sess.FindById(id).Text)
  If Err.Number <> 0 Then Err.Clear : SafeText = ""
  On Error GoTo 0
End Function

Function SafeSelected(id)
  On Error Resume Next
  SafeSelected = sess.FindById(id).Selected
  If Err.Number <> 0 Then Err.Clear : SafeSelected = False
  On Error GoTo 0
End Function

Function BoolMark(v)
  If v Then BoolMark = "X" Else BoolMark = ""
End Function

Function Clean(v)
  Clean = Replace(Replace(Replace(CStr(v), vbCr, " "), vbLf, " "), vbTab, " ")
End Function

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy And elapsed < maxMs
    WScript.Sleep 200 : elapsed = elapsed + 200
  Loop
  WScript.Sleep 500
End Sub
