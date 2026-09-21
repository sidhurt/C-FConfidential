Option Explicit
' Read-only (QS4/700 guarded copy of outputs/sap-gui-script/grab-se38-source.vbs). Opens <PROGNAME> in SE38 via Program > Display, selects all,
' and copies the source to the Windows clipboard (Utilities > Block/Clipboard
' > Copy to Clipboard). Never enters Change mode, never edits, never saves.
' Usage: cscript //nologo grab-se38-source.vbs <PROGNAME>

Dim SapGuiAuto, application, connection, session, prog, editor, title
If WScript.Arguments.Count < 1 Then
  WScript.Echo "ERR usage: grab-se38-source.vbs <PROGNAME>"
  WScript.Quit 2
End If
prog = WScript.Arguments(0)

Set SapGuiAuto = GetObject("SAPGUI")
Set application = SapGuiAuto.GetScriptingEngine
Dim ci, si, s, found
found = False
For ci = 0 To application.Children.Count - 1
  Set connection = application.Children(CLng(ci))
  For si = 0 To connection.Children.Count - 1
    Set s = connection.Children(CLng(si))
    If s.Info.SystemName = "QS4" And s.Info.Client = "700" Then
      Set session = s : found = True : Exit For
    End If
  Next
  If found Then Exit For
Next
If Not found Then WScript.Echo "ABORT no QS4/700 session" : WScript.Quit 9
WScript.Echo "SESSION|QS4/700|user=" & session.Info.User
If session.Children.Count > 1 Then WScript.Echo "ABORT modal open, not dismissed" : WScript.Quit 10

session.FindById("wnd[0]/tbar[0]/okcd").Text = "/nSE38"
session.FindById("wnd[0]").SendVKey 0
WScript.Sleep 1500

session.FindById("wnd[0]/usr/ctxtRS38M-PROGRAMM").Text = prog
session.FindById("wnd[0]/usr/radRS38M-FUNC_EDIT").Select
WScript.Sleep 300
session.FindById("wnd[0]/mbar/menu[0]/menu[2]").Select   ' Program > Display
WScript.Sleep 2500

' An include used by several main programs raises a read-only "Choose Program for <X>"
' chooser. Accept its default and continue; any other modal still aborts below.
If session.Children.Count > 1 Then
  If Left(session.FindById("wnd[1]").Text, 19) = "Choose Program for " Then
    WScript.Echo "CHOOSER|" & session.FindById("wnd[1]").Text & "|accepted default"
    session.FindById("wnd[1]").SendVKey 0
    WScript.Sleep 2500
  End If
End If

' Bail out if a modal (e.g. "does not exist") appeared
If session.Children.Count > 1 Then
  WScript.Echo "ERR modal: " & session.Children.Item(CLng(1)).Text
  On Error Resume Next
  WScript.Echo "MODALTEXT=" & session.FindById("wnd[1]/usr/txtMESSTXT1").Text
  WScript.Quit 3
End If

title = session.FindById("wnd[0]").Text
If InStr(title, "Display") = 0 Then
  WScript.Echo "ERR not on display screen. Title=" & title
  WScript.Echo "SBAR=" & session.FindById("wnd[0]/sbar").Text
  WScript.Quit 4
End If

Dim ids, i
ids = Array( _
  "wnd[0]/usr/cntlEDITOR/shellcont/shell", _
  "wnd[0]/usr/subEDITORSUBSCREEN:SAPLEDITOR_START:8430/cntlEDITOR/shellcont/shell", _
  "wnd[0]/usr/subSUBSCREEN:SAPLSEDITOR:0100/cntlEDITOR/shellcont/shell", _
  "wnd[0]/usr/tabsFUNC_TAB_STRIP/tabpSOURCE/ssubSCREEN_HEADER:SAPLEDITOR_START:8430/cntlEDITOR/shellcont/shell" )
Set editor = Nothing
For i = 0 To UBound(ids)
  On Error Resume Next
  Set editor = session.FindById(ids(i))
  If Err.Number = 0 And Not editor Is Nothing Then
    Err.Clear
    Exit For
  End If
  Set editor = Nothing
  Err.Clear
Next
On Error Goto 0
If editor Is Nothing Then
  WScript.Echo "ERR editor control not found on screen " & session.Info.ScreenNumber & " prog " & session.Info.Program
  WScript.Quit 5
End If

editor.SelectAll
WScript.Sleep 400

' Utilities > Block/Clipboard > Copy to Clipboard.
' Submenu index differs: ABAP Editor = menu[8], Function Builder = menu[7].
Dim menus, mi, copied
menus = Array( "wnd[0]/mbar/menu[3]/menu[8]/menu[3]", "wnd[0]/mbar/menu[3]/menu[7]/menu[3]" )
copied = False
For mi = 0 To UBound(menus)
  On Error Resume Next
  If session.FindById(menus(mi)).Text = "Copy to Clipboard" Then
    Err.Clear
    session.FindById(menus(mi)).Select
    If Err.Number = 0 Then
      copied = True
      Exit For
    End If
  End If
  Err.Clear
Next
On Error Goto 0
If Not copied Then
  WScript.Echo "ERR Copy to Clipboard menu not found"
  WScript.Quit 6
End If
WScript.Sleep 900

WScript.Echo "OK prog=" & prog
WScript.Echo "TITLE=" & title
On Error Resume Next
WScript.Echo "TYPE=" & session.FindById("wnd[0]/usr/txtTYPE").Text
WScript.Echo "STATUS=" & session.FindById("wnd[0]/usr/txtSTATUS_TEXT").Text
