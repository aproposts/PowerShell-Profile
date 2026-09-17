function Test-IsWindowsTerminal {
    <#
    Adapted from
    https://mikefrobbins.com/2024/05/16/detecting-windows-terminal-with-powershell/

    Changed to use the Parent property from Get-Process in pwsh (if possible) to
    avoid loading the CimCmdlets module. Since I use this test in my $PROFILE,
    it speeds things up and avoids unneccessary clutter.
    #>
    [CmdletBinding()]
    param ()

    if ($IsWindows) {
        function isWindowsTerminal([UInt32] $Id) {
            try {
                Get-Process -Id $Id -ErrorAction Stop -Verbose:$false | 
                ForEach-Object {
                    'ProcessName: {0}, Id: {1}, ParentId: {2}' -f @(
                        $_.Name,
                        $_.Id,
                        $_.Parent.Id
                    ) | Write-Verbose

                    if ($_.Name -eq 'WindowsTerminal') { return $true }
                    elseif ($_.Parent.Id) { return isWindowsTerminal($_.Parent.Id) }
                    else { return $false }
                }
            }
            catch { return $false }
        }
    }
    else {
        function isWindowsTerminal([UInt32] $Id) {
            try {
                Get-CimInstance Win32_Process -Filter "ProcessId = $Id" -ErrorAction Stop -Verbose:$false | 
                ForEach-Object {
                    'ProcessName: {0}, Id: {1}, ParentId: {2}' -f @(
                        $_.Name,
                        $_.ProcessId,
                        $_.ParentProcessId
                    ) | Write-Verbose

                    if ($_.Name -eq 'WindowsTerminal.exe') { return $true }
                    elseif ($_.ParentProcessId) { return isWindowsTerminal($_.ParentProcessId) }
                    else { return $false }
                }
            }
            catch { return $false }
        }
    }

    # Check if PowerShell version is 5.1 or below, or if running on Windows
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        return isWindowsTerminal($PID)
    }
    else {
        Write-Verbose -Message 'Exiting due to non-Windows environment'
        return $false
    }
}

if (Test-IsWindowsTerminal) {
    Import-Module 'WindowTitle'
}
