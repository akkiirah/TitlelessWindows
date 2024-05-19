$signature = @"
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();

[DllImport("user32.dll")]
public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

[DllImport("user32.dll")]
public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

public const int GWL_STYLE = -16;
public const int SWP_FRAMECHANGED = 0x0020;

public delegate void WinEventDelegate(IntPtr hWinEventHook, uint eventType, IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime);

[DllImport("user32.dll")]
public static extern IntPtr SetWinEventHook(uint eventMin, uint eventMax, IntPtr hmodWinEventProc, WinEventDelegate lpfnWinEventProc, uint idProcess, uint idThread, uint dwFlags);

[DllImport("user32.dll")]
public static extern bool UnhookWinEvent(IntPtr hWinEventHook);

public const uint EVENT_SYSTEM_FOREGROUND = 0x0003;
public const uint WINEVENT_OUTOFCONTEXT = 0x0000;
"@

# Load the necessary APIs
Add-Type -MemberDefinition $signature -Name WinAPI -Namespace Win32Functions

# Define the style bits to remove from the current style
$styleToRemove = 0x00C00000 -bor 0x00040000

# Define the action to be taken when a new window is created, moved, or focus changes
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

    # Get the foreground window handle
    $hWnd = [Win32Functions.WinAPI]::GetForegroundWindow()

    # Check if handle of the window has valid window handle
    if ($hWnd -ne [System.IntPtr]::Zero) {

        # Get the current window style
        $currentStyle = [Win32Functions.WinAPI]::GetWindowLong($hWnd, [Win32Functions.WinAPI]::GWL_STYLE)

        # Calculate the new style by removing the specified style bits from the current style
        $newStyle = $currentStyle -band (-bnot $styleToRemove)

        # Set the new window style for the foreground window
        [Win32Functions.WinAPI]::SetWindowLong($hWnd, [Win32Functions.WinAPI]::GWL_STYLE, $newStyle)
    }
}

# Set the event hook for foreground window change
$hook = [Win32Functions.WinAPI]::SetWinEventHook([Win32Functions.WinAPI]::EVENT_SYSTEM_FOREGROUND, [Win32Functions.WinAPI]::EVENT_SYSTEM_FOREGROUND, [IntPtr]::Zero, $winEventDelegate, 0, 0, [Win32Functions.WinAPI]::WINEVENT_OUTOFCONTEXT)

# Keep the script running to handle events
while ($true) {
    Start-Sleep -Seconds 1
}