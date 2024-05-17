$signature = @"
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();

[DllImport("user32.dll")]
public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

[DllImport("user32.dll")]
public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

public const int GWL_STYLE = -16; 
public const int SWP_FRAMECHANGED = 0x0020;
"@

# Load the necessary APIs
Add-Type -MemberDefinition $signature -Name WinAPI -Namespace Win32Functions

# Define the style bits to remove from the current style
$styleToRemove = 0x00C00000 -bor 0x00040000

# Continuously check for windows
while ($true) {
    
    # Get all foreground windows instead of all processes
    $hWnd = [Win32Functions.WinAPI]::GetForegroundWindow()

    # Check if handle of the window has valid window handle
    if ($hWnd -ne [System.IntPtr]::Zero) {

        # Get the current window style
        $currentStyle = [Win32Functions.WinAPI]::GetWindowLong($hWnd, [Win32Functions.WinAPI]::GWL_STYLE)
        
        # Debug
        # Write-Host "Current style for the foreground window: $currentStyle"
        
        # Calculate the new style by removing the specified style bits from the current style
        $newStyle = $currentStyle -band (-bnot $styleToRemove)
        
        # Debug
        # Write-Host "New style for the foreground window: $newStyle"

        # Set the new window style for the foreground window
        [Win32Functions.WinAPI]::SetWindowLong($hWnd, [Win32Functions.WinAPI]::GWL_STYLE, $newStyle)
        
        # Debug
        # Write-Host "Style set for the foreground window"
    }
    
    Start-Sleep -Milliseconds  1
}