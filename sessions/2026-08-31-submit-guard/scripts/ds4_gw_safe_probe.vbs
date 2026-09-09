Option Explicit
' Bounded Gateway diagnostic; no valid business payload is accepted by this harness.
Dim app, con, s, sess, i, j, mode, g, ed, elapsed, k, node, hname, hvalue, nm, val, uri
mode = WScript.Arguments(0)
Set sess = Nothing
Set app = GetObject("SAPGUI").GetScriptingEngine
For i = 0 To app.Children.Count - 1
  Set con = app.Children(CLng(i))
  For j = 0 To con.Children.Count - 1
    Set s = con.Children(CLng(j))
    If s.Info.SystemName = "DS4" And s.Info.Client = "200" Then
      If Not sess Is Nothing Then WScript.Quit 9
      Set sess = s
    End If
  Next
Next
If sess Is Nothing Then WScript.Quit 9
If sess.Info.Transaction <> "/IWFND/GW_CLIENT" Then WScript.Quit 10
Select Case mode
  Case "SET_HEADER"
    If sess.Children.Count <> 2 Then WScript.Quit 10
    If sess.FindById("wnd[1]").Text <> "Manage HTTP Request Header" Then WScript.Quit 10
    hname = WScript.Arguments(1) : hvalue = WScript.Arguments(2)
    If hname <> "RequestID" And hname <> "RepeatabilityCreation" And hname <> "Content-Type" And hname <> "Accept" Then WScript.Quit 2
    sess.FindById("wnd[1]/usr/txtIP_HEADER_NAME").Text = hname
    sess.FindById("wnd[1]/usr/txtIP_HEADER_VALUE").Text = hvalue
    sess.FindById("wnd[1]").SendVKey 0
    Ready
  Case "GET_SERVICE"
    If sess.Children.Count <> 1 Then WScript.Quit 10
    sess.FindById("wnd[0]/usr/radRB_GET").Select
    uri = "/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/?sap-client=200&$format=json"
    If WScript.Arguments.Count > 1 Then
      If WScript.Arguments(1) <> "DI" Then WScript.Quit 2
      uri = "/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/?sap-client=200&$format=json"
    End If
    sess.FindById("wnd[0]/usr/cntlURI_AREA/shellcont/shell").Text = uri
    WScript.Echo "REQUEST|GET|" & uri
    sess.FindById("wnd[0]/tbar[1]/btn[8]").Press
    Ready
    ReadResponse
  Case "ADD_HEADER_DIALOG"
    If sess.Children.Count <> 1 Then WScript.Quit 10
    sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[0]/shell").PressToolbarButton "ADD_HEADER"
    Ready
  Case "READ_STATE"
    Ready
  Case Else
    WScript.Quit 2
End Select
WScript.Echo "TITLE|" & sess.FindById("wnd[0]").Text
WScript.Echo "STATUS|" & sess.FindById("wnd[0]/sbar").Text
If sess.Children.Count > 1 Then
  WScript.Echo "DIALOG|" & sess.FindById("wnd[1]").Text
  For k = 0 To sess.FindById("wnd[1]/usr").Children.Count - 1
    Set node = sess.FindById("wnd[1]/usr").Children(CLng(k))
    WScript.Echo "CONTROL|" & node.Id & "|" & node.Text
  Next
End If
Sub ReadResponse()
  Set g = sess.FindById("wnd[0]/usr/cntlGUI_AREA/shellcont/shell/shellcont[1]/shell")
  For k = 0 To g.RowCount - 1
    nm = g.GetCellValue(CLng(k), "NAME") : val = g.GetCellValue(CLng(k), "VALUE")
    Select Case LCase(nm)
      Case "~status_code", "~status_reason", "repeatabilityresult", "content-type", "requestid", "content-length"
        WScript.Echo "HEADER|" & nm & "|" & val
    End Select
  Next
End Sub
Sub Ready()
  elapsed = 0
  Do While sess.Busy
    If elapsed >= 30000 Then WScript.Quit 13
    WScript.Sleep 100 : elapsed = elapsed + 100
  Loop
End Sub
