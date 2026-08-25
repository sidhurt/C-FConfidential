param([Parameter(Mandatory=$true)][string]$OutPath)
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Collections.Generic; using System.Runtime.InteropServices; using System.Text;
public static class WinH {
  public delegate bool Cb(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(Cb cb, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern void SwitchToThisWindow(IntPtr h, bool alt);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, uint f, IntPtr e);
  public static List<IntPtr> ByClass(string cls) {
    var res = new List<IntPtr>();
    EnumWindows((h,l) => { var sb=new StringBuilder(256); GetClassNameW(h,sb,256);
      if(sb.ToString()==cls && IsWindowVisible(h)) res.Add(h); return true; }, IntPtr.Zero);
    return res;
  }
  public static string Title(IntPtr h){ var sb=new StringBuilder(512); GetWindowTextW(h,sb,512); return sb.ToString(); }
  public static void Force(IntPtr h) {
    keybd_event(0x12, 0, 0, IntPtr.Zero); keybd_event(0x12, 0, 2, IntPtr.Zero);
    uint fgT = GetWindowThreadProcessId(GetForegroundWindow(), IntPtr.Zero);
    uint myT = GetCurrentThreadId();
    AttachThreadInput(myT, fgT, true);
    ShowWindow(h, 9); BringWindowToTop(h); SetForegroundWindow(h); SwitchToThisWindow(h, true);
    AttachThreadInput(myT, fgT, false);
  }
}
"@

$vbs = Join-Path $PSScriptRoot 'focus_editor.vbs'

function Get-Body {
    # 1. SAP-internal focus into the request-body editor.
    #    This launches cscript, so it MUST happen before the foreground force --
    #    a process launch steals foreground and the keystrokes would land elsewhere.
    $focus = & cscript.exe //nologo $vbs 2>&1
    if ($focus -notmatch 'FOCUS_OK') { throw "focus step refused: $focus" }

    # 2. Foreground the SAP session window (pure Win32, no process launch).
    $wins = [WinH]::ByClass("SAP_FRONTEND_SESSION")
    if ($wins.Count -eq 0) { throw "no visible SAP_FRONTEND_SESSION window" }
    $target = $wins[0]
    for ($try = 0; $try -lt 5; $try++) {
        [WinH]::Force($target); Start-Sleep -Milliseconds 700
        if ([WinH]::GetForegroundWindow() -eq $target) { break }
    }
    if ([WinH]::GetForegroundWindow() -ne $target) {
        throw "REFUSED: could not foreground SAP (front is '$([WinH]::Title([WinH]::GetForegroundWindow()))'); no keys sent"
    }

    # 3. Select-all + copy, with the clipboard cleared first so a stale
    #    clipboard can never masquerade as a captured response.
    [System.Windows.Forms.Clipboard]::Clear(); Start-Sleep -Milliseconds 300
    if (-not [string]::IsNullOrEmpty([System.Windows.Forms.Clipboard]::GetText())) { throw "clipboard would not clear" }
    [System.Windows.Forms.SendKeys]::SendWait("^a"); Start-Sleep -Milliseconds 600
    [System.Windows.Forms.SendKeys]::SendWait("^c"); Start-Sleep -Milliseconds 1600

    $b = $null
    for ($i=0; $i -lt 12 -and [string]::IsNullOrEmpty($b); $i++) {
        try { $b = [System.Windows.Forms.Clipboard]::GetText() } catch { }
        if ([string]::IsNullOrEmpty($b)) { Start-Sleep -Milliseconds 350 }
    }
    return $b
}

$body = $null
for ($attempt = 1; $attempt -le 3; $attempt++) {
    try { $body = Get-Body } catch { Write-Host "attempt $attempt : $_"; Start-Sleep -Milliseconds 800; continue }
    if ([string]::IsNullOrEmpty($body)) { Write-Host "attempt $attempt : clipboard empty"; continue }
    # HARD GUARD: the payload must look like an OData/HTTP response body.
    # Without this a failed keystroke silently captures whatever else was on the clipboard.
    $t = $body.TrimStart([char]0xFEFF,' ',"`t","`r","`n")
    if ($t -match '^(<\?xml|<edmx:|<\w+:?\w*[\s>]|\{|\[)') { break }
    Write-Host "attempt $attempt : REJECTED - captured text is not a response body (starts: '$($t.Substring(0,[Math]::Min(60,$t.Length)))')"
    $body = $null
}
if ([string]::IsNullOrEmpty($body)) { throw "CAPTURE FAILED: no valid response body obtained after 3 attempts" }

# never let a session artefact reach the evidence tree
$body = [regex]::Replace($body,'(?i)(SAP_SESSIONID_[A-Z0-9_]+=)[^;"<\s]+','$1[REDACTED]')
$body = [regex]::Replace($body,'(?i)(x-csrf-token"?\s*[:=]\s*"?)[^",<\s]+','$1[REDACTED]')

Set-Content -LiteralPath $OutPath -Value $body -Encoding UTF8 -NoNewline
[System.Windows.Forms.Clipboard]::Clear()
$len = (Get-Item -LiteralPath $OutPath).Length
$sha = (Get-FileHash -LiteralPath $OutPath -Algorithm SHA256).Hash
"CAPTURED`t{0}`t{1} bytes`tsha256={2}" -f (Split-Path $OutPath -Leaf), $len, $sha
