param (
    [Parameter(Mandatory=$true)]
    [string]$IncomingRoot,  # e.g. \\wosext3...\Incoming

    [Parameter(Mandatory=$true)]
    [string]$DestinationDir,

    [string]$SearchString = "PTL_PR01_XXXX-XXXODCA_CPRF_SED5_01E50692"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Step 1: Get the latest BSP folder
$latestBspFolder = Get-ChildItem -Path $IncomingRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latestBspFolder) {
    Write-Host "No BSP folders found in $IncomingRoot"
    exit
}

Write-Host "Latest BSP folder: $($latestBspFolder.Name)"

# Step 2: Find the latest IFWI zip file
$packagesPath = Join-Path $latestBspFolder.FullName "Packages"
$latestZip = Get-ChildItem -Path $packagesPath -Filter "IFWI_PTLH_A0B0_PSPP_Release_*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latestZip) {
    Write-Host "No IFWI zip files found in $packagesPath"
    exit
}

Write-Host "Latest IFWI zip: $($latestZip.Name)"

# Step 3: Extract matching .bin file
if (-not (Test-Path $DestinationDir)) {
    New-Item -ItemType Directory -Path $DestinationDir | Out-Null
}

$zip = [System.IO.Compression.ZipFile]::OpenRead($latestZip.FullName)

$found = $false
foreach ($entry in $zip.Entries) {
    if ($entry.FullName -like "*$SearchString*.bin") {
        $outputPath = Join-Path $DestinationDir $entry.Name
        $entry.ExtractToFile($outputPath, $true)
        Write-Host "Extracted: $($entry.FullName) to $outputPath"
        $found = $true
    }
}

$zip.Dispose()

if (-not $found) {
    Write-Host "No matching .bin file found in $($latestZip.Name)"
}
