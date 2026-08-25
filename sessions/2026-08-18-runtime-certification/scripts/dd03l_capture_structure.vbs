Option Explicit
' Read-only DDIC structure field capture via SE16/DD03L classic list.
' Usage: cscript //nologo dd03l_capture_structure.vbs <STRUCTURE> <OUT_TSV>
Dim sapGuiAuto, app, conn, sess, structName, outPath, elapsed, fso, out, usr
Dim pos, maxPos, nextPos, y, fieldName, position, keyFlag, mandatory, rollName, checkTable, seen, rowKey
If WScript.Arguments.Count < 2 Then WScript.Echo "USAGE|<STRUCTURE>|<OUT_TSV>" : WScript.Quit 1
structName = UCase(WScript.Arguments(0))
outPath = WScript.Arguments(1)
Set sapGuiAuto = GetObject("SAPGUI")
Set app = sapGuiAuto.GetScriptingEngine
Set conn = app.Children(CLng(0))
Set sess = conn.Children(CLng(0))
If sess.Info.SystemName <> "DS4" Or sess.Info.Client <> "200" Then WScript.Echo "REFUSED" : WScript.Quit 9
Set fso = CreateObject("Scripting.FileSystemObject")
Set out = fso.CreateTextFile(outPath, True, True)
Set seen = CreateObject("Scripting.Dictionary")

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE16"
sess.FindById("wnd[0]").SendVKey 0
Ready 20000
sess.FindById("wnd[0]/usr/ctxtDATABROWSE-TABLENAME").Text = "DD03L"
sess.FindById("wnd[0]").SendVKey 0
Ready 25000
sess.FindById("wnd[0]/usr/ctxtI1-LOW").Text = structName
sess.FindById("wnd[0]/usr/ctxtI3-LOW").Text = "A"
On Error Resume Next
sess.FindById("wnd[0]/usr/txtMAX_SEL").Text = "500"
Err.Clear
On Error GoTo 0
sess.FindById("wnd[0]").SendVKey 8
Ready 60000
out.WriteLine "Structure" & vbTab & "FieldName" & vbTab & "Position" & vbTab & "KeyFlag" & vbTab & "Mandatory" & vbTab & "DataElement" & vbTab & "CheckTable"
If InStr(UCase(sess.FindById("wnd[0]").Text), "SELECT ENTRIES") = 0 Then
  out.Close : WScript.Echo "NO_RESULT|" & structName & "|" & sess.FindById("wnd[0]/sbar").Text : WScript.Quit 4
End If
Set usr = sess.FindById("wnd[0]/usr")
On Error Resume Next
pos = usr.VerticalScrollbar.Position
maxPos = usr.VerticalScrollbar.Maximum
If Err.Number <> 0 Then Err.Clear : pos = 0 : maxPos = 0
On Error GoTo 0
pos = 0
Do
  On Error Resume Next
  usr.VerticalScrollbar.Position = pos
  Err.Clear
  On Error GoTo 0
  Ready 2500
  For y = 5 To 39
    fieldName = Cell("lbl[36," & y & "]")
    position = Cell("lbl[84," & y & "]")
    If Len(fieldName) > 0 Then
      rowKey = position & "|" & fieldName
      If Not seen.Exists(rowKey) Then
        seen.Add rowKey, True
        keyFlag = Cell("lbl[93," & y & "]")
        mandatory = Cell("lbl[101," & y & "]")
        rollName = Cell("lbl[111," & y & "]")
        checkTable = Cell("lbl[144," & y & "]")
        out.WriteLine structName & vbTab & fieldName & vbTab & position & vbTab & keyFlag & vbTab & mandatory & vbTab & rollName & vbTab & checkTable
      End If
    End If
  Next
  nextPos = pos + 30
  If nextPos > maxPos Then nextPos = maxPos
  If nextPos <= pos Then Exit Do
  pos = nextPos
Loop
out.Close
WScript.Echo "CAPTURED_DDIC|" & structName & "|Fields=" & seen.Count & "|" & outPath

Function Cell(suffix)
  On Error Resume Next
  Cell = Clean(sess.FindById("wnd[0]/usr/" & suffix).Text)
  If Err.Number <> 0 Then Err.Clear : Cell = ""
  On Error GoTo 0
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
