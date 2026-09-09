# Capture a SAP GUI window to PNG, selecting it by window title.
# Usage: powershell -File shot.ps1 -Name proof01 [-TitleMatch "Class Builder"]
param(
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$TitleMatch = "",
  [string]$OutDir = "C:\Users\sidmy\Downloads\shree-cement-cnf-agent-cowork-20260729T062834Z-1-001\shree-cement-cnf-agent-cowork\sessions\2026-09-02-std-api-extension-feasibility\shots"
)

Add-Type -AssemblyName System.Drawing

$sig = @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class W32 {
  public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr hWnd, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr hWnd, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

  public static List<string> Found = new List<string>();
  public static List<IntPtr> Handles = new List<IntPtr>();
  public static void Scan() {
    Found.Clear(); Handles.Clear();
    EnumWindows(delegate(IntPtr h, IntPtr l) {
      if (!IsWindowVisible(h)) return true;
      StringBuilder t = new StringBuilder(512); GetWindowTextW(h, t, 512);
      StringBuilder c = new StringBuilder(256); GetClassNameW(h, c, 256);
      if (c.ToString().StartsWith("SAP_FRONTEND") || c.ToString().Contains("SAPGUI")) {
        if (t.Length > 0) { Found.Add(t.ToString()); Handles.Add(h); }
      }
      return true;
    }, IntPtr.Zero);
  }
}
'@
if (-not ("W32" -as [type])) { Add-Type -TypeDefinition $sig }

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

[W32]::Scan()
if ([W32]::Found.Count -eq 0) { Write-Output "ERR no SAP windows found"; exit 1 }

$idx = 0
if ($TitleMatch) {
  $idx = -1
  for ($i = 0; $i -lt [W32]::Found.Count; $i++) {
    if ([W32]::Found[$i] -like "*$TitleMatch*") { $idx = $i; break }
  }
  if ($idx -lt 0) {
    Write-Output ("ERR no window matching '{0}'. Windows: {1}" -f $TitleMatch, ([W32]::Found -join ' | '))
    exit 2
  }
}

$h = [W32]::Handles[$idx]
$title = [W32]::Found[$idx]
[W32]::ShowWindow($h, 9) | Out-Null
[W32]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 900

$r = New-Object W32+RECT
[W32]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left; $hg = $r.Bottom - $r.Top
if ($w -le 0 -or $hg -le 0) { Write-Output "ERR bad bounds"; exit 3 }

$bmp = New-Object System.Drawing.Bitmap $w, $hg
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
$path = Join-Path $OutDir "$Name.png"
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

Write-Output ("OK {0}  {1}x{2}" -f $path, $w, $hg)
Write-Output ("TITLE {0}" -f $title)
