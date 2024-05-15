$signature = @"
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();

[DllImport("user32.dll")]
public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

[DllImport("user32.dll")]
public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

[DllImport("user32.dll")]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

public const int GWL_STYLE = -16;
public const int SWP_FRAMECHANGED = 0x0020;
"@

# Load the necessary APIs
Add-Type -MemberDefinition $signature -Name WinAPI -Namespace Win32Functions

# Get all processes except explorer.exe
$processes = Get-Process | Where-Object { $_.ProcessName -ne "explorer" }

foreach ($process in $processes) {

    # Get the main window handle of the process
    $hWnd = $process.MainWindowHandle

    # Check if the process has a main window and it's visible
    if ($hWnd -ne [System.IntPtr]::Zero -and $process.MainWindowTitle) {
        Write-Host "Processing window: $($process.MainWindowTitle)"

        # Get current window style
        $currentStyle = [Win32Functions.WinAPI]::GetWindowLong($hWnd, [Win32Functions.WinAPI]::GWL_STYLE)
        Write-Host "Current style for $($process.MainWindowTitle): $currentStyle"

        # Define style to cut titlebar
        $styleToRemove = 0x00C00000 # WS_CAPTION + WS_BORDER
        $newStyle = $currentStyle -band (-bnot $styleToRemove)
        Write-Host "New style for $($process.MainWindowTitle): $newStyle"

        # Set new style
        [Win32Functions.WinAPI]::SetWindowLong($hWnd, [Win32Functions.WinAPI]::GWL_STYLE, $newStyle)

        Write-Host "Style set for $($process.MainWindowTitle)"
    }
}
