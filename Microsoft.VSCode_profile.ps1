# EditorServicesCommandSuite module configuration
Import-CommandSuite
Set-CommandSuiteSetting CommandSplatRefactor.NoNewLineAfterHashtable -Value $true

Import-Module posh-git
Invoke-Build.ArgumentCompleters.ps1