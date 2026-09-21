Option Explicit
' Read-only QS4/700 source capture.
' Opens one active ABAP program/include in SE38 Display and writes the editor text.
' Never selects Change, executes the program, saves, activates, or dismisses a modal.
' Usage: cscript //nologo qs4_se38_capture_source.vbs <PROGRAM> <OUTFILE>

Dim app, conn, candidate, sess, i, j, prog, outFile, elapsed
Dim editor, fso, stream, lineNo, sourceText

If WScript.Arguments.Count <> 2 Then
  WScript.Echo "USAGE|PROGRAM OUTFILE"
  WScript.Quit 2
End If

prog = UCase(CStr(WScript.Arguments(0)))
outFile = CStr(WScript.Arguments(1))
Set sess = Nothing
Set app = GetObject("SAPGUI").GetScriptingEngine

For i = 0 To app.Children.Count - 1
  Set conn = app.Children(CLng(i))
  For j = 0 To conn.Children.Count - 1
    Set candidate = conn.Children(CLng(j))
    If candidate.Info.SystemName = "QS4" And candidate.Info.Client = "700" Then
      If Not sess Is Nothing Then
        WScript.Echo "ABORT|AMBIGUOUS_QS4_700_SESSION"
        WScript.Quit 9
      End If
      Set sess = candidate
    End If
  Next
Next

If sess Is Nothing Then WScript.Echo "ABORT|NO_QS4_700" : WScript.Quit 9
If sess.Children.Count > 1 Then
  WScript.Echo "ABORT|MODAL_BEFORE|" & SafeText("wnd[1]")
  WScript.Quit 10
End If

WScript.Echo "SESSION|" & sess.Info.SystemName & "/" & sess.Info.Client & _
  "|USER=" & sess.Info.User & "|BEFORE=" & sess.Info.Transaction

sess.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE38"
sess.FindById("wnd[0]").SendVKey 0
Ready 30000
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_AFTER_NAV|" & SafeText("wnd[1]") : WScript.Quit 11

sess.FindById("wnd[0]/usr/ctxtRS38M-PROGRAMM").Text = prog
sess.FindById("wnd[0]/mbar/menu[0]/menu[2]").Select
Ready 60000
If sess.Children.Count > 1 Then WScript.Echo "ABORT|MODAL_AFTER_DISPLAY|" & SafeText("wnd[1]") : WScript.Quit 12

WScript.Echo "DISPLAY|" & prog & "|TITLE=" & SafeText("wnd[0]") & "|STATUS=" & SafeText("wnd[0]/sbar")
Set editor = Nothing
FindEditor sess.FindById("wnd[0]/usr")
If editor Is Nothing Then WScript.Echo "ABORT|NO_EDITOR|" & prog : WScript.Quit 13

sourceText = ""
If editor.SubType = "AbapEditor" Then
  For lineNo = 1 To editor.GetLineCount()
    sourceText = sourceText & editor.GetLineText(CLng(lineNo)) & vbCrLf
  Next
Else
  sourceText = editor.Text
End If

Set fso = CreateObject("Scripting.FileSystemObject")
Set stream = fso.CreateTextFile(outFile, True, True)
stream.Write sourceText
stream.Close
WScript.Echo "OK|" & prog & "|CHARS=" & Len(sourceText) & "|OUT=" & outFile

Sub Ready(ByVal maxMs)
  elapsed = 0
  Do While sess.Busy
    If elapsed >= maxMs Then WScript.Echo "ABORT|BUSY_TIMEOUT" : WScript.Quit 14
    WScript.Sleep 100
    elapsed = elapsed + 100
  Loop
  WScript.Sleep 300
End Sub

Sub FindEditor(node)
  Dim nodeType, nodeSubType, isContainer, childIndex, child
  nodeType = "" : nodeSubType = "" : isContainer = False
  On Error Resume Next
  nodeType = node.Type
  nodeSubType = node.SubType
  isContainer = node.ContainerType
  On Error GoTo 0

  If nodeType = "GuiTextedit" Or nodeSubType = "TextEdit" Or nodeSubType = "AbapEditor" Then
    Set editor = node
    Exit Sub
  End If

  If isContainer Then
    For childIndex = 0 To node.Children.Count - 1
      Set child = node.Children.Item(CLng(childIndex))
      If editor Is Nothing Then FindEditor child
    Next
  End If
End Sub

Function SafeText(ByVal id)
  On Error Resume Next
  SafeText = sess.FindById(id).Text
  If Err.Number <> 0 Then SafeText = ""
  Err.Clear
  On Error GoTo 0
End Function
