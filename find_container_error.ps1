
Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $file = $_.FullName
    $lines = Get-Content $file
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "Container\(") {
            $context = ""
            for ($j = $i; $j -lt [Math]::Min($i + 20, $lines.Count); $j++) {
                $context += $lines[$j]
            }
            if ($context -match "color:" -and $context -match "decoration:") {
                Write-Host "$file : Line $($i+1)"
                Write-Host $context
                Write-Host "---"
            }
        }
    }
}
