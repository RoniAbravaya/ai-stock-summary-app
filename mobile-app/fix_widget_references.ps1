# PowerShell script to fix widget references
$ErrorActionPreference = "Stop"

# Get all Dart files
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

# Process each file
foreach ($file in $dartFiles) {
    Write-Host "Processing $($file.FullName)"
    $content = Get-Content $file.FullName -Raw
    $content = $content -replace 'widgets\.', 'widgets/'
    $content | Set-Content $file.FullName -NoNewline
}

Write-Host "Widget references fixed successfully"
