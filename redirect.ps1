. (
    [Environment]::GetFolderPath('MyDocuments') |
        Join-Path -ChildPath 'MyPowerShell' |
        Join-Path -ChildPath (Split-Path -Leaf $PSCommandPath)
)
