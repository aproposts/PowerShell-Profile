# Aliases
@{
    # Built-in/System Commands
    gh     = 'Get-Help'
    mc     = 'Measure-Command'
    popl   = 'Pop-Location'
    pul    = 'Push-Location'
    rvdns  = 'Resolve-DnsName'
    # Installed Module Commands
    gs     = 'Get-Secret'
    gsi    = 'Get-SecretInfo'
    ib     = 'Invoke-Build'
    # Installed Scripts
    nsmbm  = 'New-SmbMapping.ps1'
    scc    = 'Set-ClipboardCredential.ps1'
    sapsac = 'Start-ProcessAsCredential.ps1'
    # 'Start-As' = 'Start-ProcessAsCredential.ps1'
    # Personal Scripts
    fdou   = 'Find-OcadUser.ps1'
    gdl    = 'Get-Download.ps1'
    gss    = 'Get-Screenshot.ps1'
    gwf    = 'Get-WorkFolder.ps1'
    nwf    = 'New-WorkFolder.ps1'
    iec    = 'Invoke-EmacsClient.ps1'
    ivsc   = 'Invoke-VisualStudioCode.ps1'
    ttc    = 'Test-TCPConnection.ps1'
}.GetEnumerator() | ForEach-Object {
    Set-Alias -Name $_.Key -Value $_.Value
}

# Default Parameter Configuration
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values
@{
    # Toggle $PSDefaultParameterValues
    Disabled                                  = $false
    # Built-in/System Commands
    'New-PSSession:Credential'                = { Get-Secret }
    # Installed Module Commands
    'Test-PendingReboot:SkipConfigurationMan' = $true
    'Get-Secret:Name'                         = 'sys'
    'Get-SecretInfo:Vault'                    = 'SecretStore'
    # Installed Scripts
    'Get-LapsCredential.ps1:Credential'       = { Get-Secret }
    'New-SmbMapping.ps1:Credential'           = { Get-Secret }
    'Set-ClipboardCredential.ps1:Password'    = $true
    'Set-ClipboardCredential.ps1:AsPlainText' = $true
    'Set-ClipboardCredential.ps1:Timeout'     = { New-TimeSpan -Seconds 10 }
    # Personal Scripts
}.GetEnumerator() | ForEach-Object {
    $PSDefaultParameterValues[$_.Key] = $_.Value
}

# If running new/core PowerShell on Windows, add the Windows PowerShell
# CurrentUser module path location to the PSModulePath.
if ($IsWindows) {
    & {
        $modulePathArray = [System.Collections.ArrayList] $env:PSModulePath.Split(';')
        $userWinModulePath = [System.Environment]::GetFolderPath('MyDocuments') |
            Join-Path -ChildPath 'WindowsPowerShell' |
            Join-Path -ChildPath 'Modules'

        if ($userWinModulePath -notin $modulePathArray) {
            $modulePathArray.Insert(1, $userWinModulePath) | Out-Null
            $env:PSModulePath = $modulePathArray -join ';'
        }
    }
}

# If running either PowerShell version on Windows, add locations to the
# environment path and PSModulePath.
if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
    & {
        # # Add MyPowerShell Scripts location to the environment path.
        # $myScriptPath = '{0}\MyPowerShell\Scripts' -f [System.Environment]::GetFolderPath('MyDocuments')
        # $envPathArray = [System.Collections.ArrayList] $env:Path.Split(';')

        # if ($myScriptPath -notin $envPathArray) {
        #     $envPathArray.Insert(0, $myScriptPath) | Out-Null
        #     $env:Path = $envPathArray -join ';'
        # }

        # Add MyPowerShell Modules location to the module path.
        $myPSModulePath = '{0}\MyPowerShell\Modules' -f [System.Environment]::GetFolderPath('MyDocuments') 
        $modulePathArray = [System.Collections.ArrayList] $env:PSModulePath.Split(';')

        if ($myPSModulePath -notin $modulePathArray) {
            $modulePathArray.Insert(0, $myPSModulePath) | Out-Null
            $env:PSModulePath = $modulePathArray -join ';'
        }
    }
}

# PSReadline Configuration
if ($PSReadline = Get-Module -Name PSReadLine) {
    switch ($PSReadLine.Version) {
        #     { $_ -ge 2.2 -and $PSVersionTable.PSVersion -gt '7.2' } {
        #         Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        #     }
        #     { $_ -ge 2.1 -and $_ -lt 2.2 -and $PSVersionTable.PSVersion -lt '7.2' } {
        #         Set-PSReadLineOption -PredictionSource History
        #     }
        { $_ -ge 2.1 } {
            Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]27)[90;7;3m" }
        }
    }

    # Set-PSReadLineKeyHandler -Key Tab -Function Complete # Redundant in Emacs EditMode
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineKeyHandler -Key @('UpArrow', 'Ctrl+p') -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key @('DownArrow', 'Ctrl+n') -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key 'Ctrl+Spacebar' -Function SetMark
    Set-PSReadLineKeyHandler -Key 'Ctrl+v' -Function Paste
    Set-PSReadLineKeyHandler -Key 'Ctrl+/' -Function Undo
    Set-PSReadLineKeyHandler -Key 'Ctrl+?' -Function Redo

    # Custom KeyHandlers to make the terminal behave more like Emacs, where the
    # latest addition to the kill ring is copied to the clipboard.

    @{
        Chord            = 'Ctrl+k'
        BriefDescription = 'CopyKillLine'
        Description      = 'Copy to clipboard when calling KillLine'
        ScriptBlock      = {
            param($key, $arg)

            $bufferString = [string] $null
            $point = [int32] $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$bufferString, [ref]$point)

            $bufferString.Substring($point) | Set-Clipboard

            [Microsoft.PowerShell.PSConsoleReadLine]::KillLine()
        }
    } | ForEach-Object { Set-PSReadLineKeyHandler @_ }

    @{
        Chord            = 'Ctrl+w'
        BriefDescription = 'CutRegion'
        Description      = 'Cut region to clipboard and kill ring'
        ScriptBlock      = {
            param($key, $arg)

            $bufferString = [string] $null
            $point = $mark = [int32] $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$bufferString, [ref]$point)
            [Microsoft.PowerShell.PSConsoleReadLine]::ExchangePointAndMark()
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$bufferString, [ref]$mark)
            [Microsoft.PowerShell.PSConsoleReadLine]::ExchangePointAndMark()

            if ($point -gt $mark) {
                $bufferString.Substring($mark, $point - $mark) | Set-Clipboard
            }
            elseif ($mark -gt $point) {
                $bufferString.Substring($point, $mark - $point) | Set-Clipboard
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::KillRegion()
        }
    } | ForEach-Object { Set-PSReadLineKeyHandler @_ }

    @{
        Chord            = 'Alt+w'
        BriefDescription = 'CopyRegion'
        Description      = 'Copy region to clipboard and kill ring'
        ScriptBlock      = {
            param($key, $arg)

            $bufferString = [string] $null
            $point = $mark = [int32] $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$bufferString, [ref]$point)
            [Microsoft.PowerShell.PSConsoleReadLine]::ExchangePointAndMark()
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$bufferString, [ref]$mark)
            [Microsoft.PowerShell.PSConsoleReadLine]::ExchangePointAndMark()

            if ($mark -lt $point) {
                $bufferString.Substring($mark, $point - $mark) | Set-Clipboard
            }
            elseif ($point -lt $mark) {
                $bufferString.Substring($point, $mark - $point) | Set-Clipboard
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::KillRegion()
            [Microsoft.PowerShell.PSConsoleReadLine]::Yank()
            if ($point -lt $mark) { 
                [Microsoft.PowerShell.PSConsoleReadLine]::ExchangePointAndMark()
            }
        }
    } | ForEach-Object { Set-PSReadLineKeyHandler @_ }

    # Selections from the Sample PSReadLine Profile
    # https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
    
    # This example will replace any aliases on the command line with the resolved commands.
    @{
        Chord            = 'Alt+%'
        BriefDescription = 'ExpandAliases'
        Description      = 'Replace all aliases with the full command'
        ScriptBlock      = {
            param($key, $arg)

            $ast = $null
            $tokens = $null
            $errors = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
    
            $startAdjustment = 0
            foreach ($token in $tokens) {
                if ($token.TokenFlags -band [System.Management.Automation.Language.TokenFlags]::CommandName) {
                    $alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
                    if ($alias -ne $null) {
                        $resolvedCommand = $alias.ResolvedCommandName
                        if ($resolvedCommand -ne $null) {
                            $extent = $token.Extent
                            $length = $extent.EndOffset - $extent.StartOffset
                            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                                $extent.StartOffset + $startAdjustment,
                                $length,
                                $resolvedCommand)
    
                            # Our copy of the tokens won't have been updated, so we need to
                            # adjust by the difference in length
                            $startAdjustment += ($resolvedCommand.Length - $length)
                        }
                    }
                }
            }
        }
    } | ForEach-Object { Set-PSReadLineKeyHandler @_ }

    # F1 for help on the command line - naturally
    @{
        Chord            = 'Ctrl+F1'
        BriefDescription = 'CommandHelp'
        Description      = 'Open the help window for the current command'
        ScriptBlock      = {
            param($key, $arg)

            $ast = $null
            $tokens = $null
            $errors = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
    
            $commandAst = $ast.FindAll( {
                    $node = $args[0]
                    $node -is [System.Management.Automation.Language.CommandAst] -and
                    $node.Extent.StartOffset -le $cursor -and
                    $node.Extent.EndOffset -ge $cursor
                }, $true) | Select-Object -Last 1
    
            if ($commandAst -ne $null) {
                $commandName = $commandAst.GetCommandName()
                if ($commandName -ne $null) {
                    $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
                    if ($command -is [System.Management.Automation.AliasInfo]) {
                        $commandName = $command.ResolvedCommandName
                    }
    
                    if ($commandName -ne $null) {
                        Get-Help $commandName -ShowWindow
                    }
                }
            }
        }
    } | ForEach-Object { Set-PSReadLineKeyHandler @_ }
}

function prompt {
    # Define variables locally to prevent scope conflicts.
    # Use an ordered hashtable to define the parts of the prompt.
    $local:prompt = [ordered] @{
        psVer = "PS$($PSVersionTable.PSVersion.Major) "
    }

    # Stylize the PSVersion part of the prompt if the host is ANSI capable.
    if ($Host.UI.SupportsVirtualTerminal) {
        $local:esc = $([char]27)
        $prompt.psVer = "$esc[3m$esc[38;5;8m{0}$esc[0m" -f $prompt.psVer
    }

    # Use ProviderPath if there's no drive defined for the location provider.
    $prompt.path = if ($executionContext.SessionState.Path.CurrentLocation.Drive) {
        $executionContext.SessionState.Path.CurrentLocation.Path
    }
    else {
        $executionContext.SessionState.Path.CurrentLocation.ProviderPath
    }

    # Only provide Git info if the host supports ANSI colors...
    if ($Host.UI.SupportsVirtualTerminal -and 
        # ...the posh-git moduled is loaded...
        (Get-Module 'posh-git') -and 
        # ...and we're in a repository.
        ($prompt.git = "$(Write-GitStatus (Get-GitStatus))".Trim(' '))
    ) {
        $prompt.git = ':' + $prompt.git
    }

    # As per the default, indicate when the prompt is nested.
    $prompt.prompt = "$('>' * ($nestedPromptLevel + 1)) "

    # Define a function to measure the prompt length excluding ANSI control characters.
    function promptLength {
        return [regex]::Replace(
            ($prompt.Values -join ''),
            '\x1B\[[0-9;]+m',
            ''
        ).Length
    }

    # Set the maximum prompt length as a fraction of the console width.
    $local:maxLength = [uint16]($Host.UI.RawUI.BufferSize.Width * 0.5) # Use 'BufferSize' to support ISE.
    # ...or try to reserve a given amount of space.
    # $maxLength = $Host.UI.RawUI.BufferSize.Width - 80 # Use 'BufferSize' to support ISE.

    if ((promptLength) -gt $maxLength) {
        # Collapse the $HOME path to '~'.
        if ($prompt.path -like "$HOME*") { $prompt.path = $prompt.path.Replace($HOME, '~') }

        # Use the system path delimiter.
        $local:dsc = [System.IO.Path]::DirectorySeparatorChar

        # Isolate the first element of the path which may begin with DSC characters (as in a UNC path).
        $local:segments = [regex]::Match(
            $prompt.path,
            "(?<first>\$($dsc){0,2}[^\$($dsc)]*)\$($dsc)?(?<rest>.*)"
        ) | ForEach-Object { 
            $_.Groups['first'].Value
            $_.Groups['rest'].Value.Split($dsc)
        }
        
        # Collapse parts of the path (staring with the 2nd) until the prompt is
        # short enough, or the penultimate array element has been collapsed.
        while ((promptLength) -gt $maxLength -and (++$local:i -lt ($segments.Length - 1))) {
            $segments[$i] = '..'
            $prompt.path = $segments -join $dsc
        }
    }

    return $prompt.Values -join ''

    # The default prompt function definition:
    # "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
}
