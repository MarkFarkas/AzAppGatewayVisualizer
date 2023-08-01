# Dot-source the functions from the "Public" folder
$PublicItems = Get-ChildItem -Path $PSScriptRoot\Public\*.ps1
foreach ($item in $PublicItems) {
    . $item.FullName
}

# Export the functions from the "Public" folder
Export-ModuleMember -Function *