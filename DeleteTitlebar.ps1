$signature = @"
using System;
using System.Runtime.InteropServices;
public static class WinAPI
{
    // Delegate for window enumeration
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    public const int GWL_STYLE = -16;

    // Delegate and functions for WinEvent hooks
    public delegate void WinEventDelegate(IntPtr hWinEventHook, uint eventType, IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime);

    [DllImport("user32.dll")]
    public static extern IntPtr SetWinEventHook(uint eventMin, uint eventMax, IntPtr hmodWinEventProc, WinEventDelegate lpfnWinEventProc, uint idProcess, uint idThread, uint dwFlags);

    [DllImport("user32.dll")]
    public static extern bool UnhookWinEvent(IntPtr hWinEventHook);

    public const uint EVENT_OBJECT_SHOW = 0x8002;
    public const uint WINEVENT_OUTOFCONTEXT = 0x0000;

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
"@

# Load the necessary APIs
Add-Type -MemberDefinition $signature -Name WinAPI -Namespace Win32Functions

# Define the style bits to remove from the current style
$styleToRemove = 0x00C00000 -bor 0x00040000

# Get the directory of the script and the path for the excluded processes file
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$excludedProcessesPath = Join-Path -Path $scriptDirectory -ChildPath "ExcludedProcesses.txt"

# If the file does not exist, use an empty list to adjust style for all processes
if (-Not (Test-Path $excludedProcessesPath)) {
    $excludedProcesses = @()
} else {
    $excludedProcesses = Get-Content -Path $excludedProcessesPath
}

function Process-Window {
    param(
        [System.IntPtr]$hwnd
    )
    if ($hwnd -eq [System.IntPtr]::Zero) { return }
    if (-not [Win32Functions.WinAPI]::IsWindowVisible($hwnd)) { return }

    [uint32]$processId = 0
    [Win32Functions.WinAPI]::GetWindowThreadProcessId($hwnd, [ref]$processId) | Out-Null

    try {
        $process = Get-Process -Id $processId -ErrorAction Stop
    }
    catch {
        return
    }

    if ($excludedProcesses -contains $process.ProcessName) { return }

    $currentStyle = [Win32Functions.WinAPI]::GetWindowLong($hwnd, [Win32Functions.WinAPI]::GWL_STYLE)
    $newStyle = $currentStyle -band (-bnot $styleToRemove)
    [Win32Functions.WinAPI]::SetWindowLong($hwnd, [Win32Functions.WinAPI]::GWL_STYLE, $newStyle) | Out-Null
}

# Enumerate all existing top-level windows to adjust their style
$enumCallback = [Win32Functions.WinAPI+EnumWindowsProc]{
    param([IntPtr]$hwnd, [IntPtr]$lParam)
    Process-Window $hwnd
    return $true
}
[Win32Functions.WinAPI]::EnumWindows($enumCallback, [IntPtr]::Zero) | Out-Null

# Delegate for the EVENT_OBJECT_SHOW to process newly displayed windows
$winEventDelegate = [Win32Functions.WinAPI+WinEventDelegate]{
    param(
        [IntPtr]$hWinEventHook,
        [uint32]$eventType,
        [IntPtr]$hwnd,
        [int]$idObject,
        [int]$idChild,
        [uint32]$dwEventThread,
        [uint32]$dwmsEventTime
    )
    if ($idObject -ne 0) { return }
    if ($hwnd -eq [System.IntPtr]::Zero) { return }
    Process-Window $hwnd
}

# Set the event hook for EVENT_OBJECT_SHOW; exit silently if it fails
$hook = [Win32Functions.WinAPI]::SetWinEventHook(
    [Win32Functions.WinAPI]::EVENT_OBJECT_SHOW,
    [Win32Functions.WinAPI]::EVENT_OBJECT_SHOW,
    [IntPtr]::Zero,
    $winEventDelegate,
    0,
    0,
    [Win32Functions.WinAPI]::WINEVENT_OUTOFCONTEXT
)
if ($hook -eq [IntPtr]::Zero) { exit }

# Register a termination handler to unhook the event when the script exits
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    [Win32Functions.WinAPI]::UnhookWinEvent($hook) | Out-Null
}

# Keep the script running to handle events
while ($true) {
    Start-Sleep -Seconds 1
}
