param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$IncomingRoot,  # Root path to the Incoming folder

    [Parameter(Mandatory = $true)]
    [string]$DestinationDir,  # Where to extract the .bin file

    [string]$SearchString = "PTL_PR01_XXXX-XXXODCA_CPRF_SED5_01E50692",  # Pattern to match in .bin filename

    [string]$BspFilter = "*",  # Optional: filter BSP folder names
    [string]$ZipFilter = "IFWI_PTLH_A0B0_PSPP_Release_*.zip"  # Optional: filter zip file names
)

function Get-LatestBspFolder {
    param ([string]$RootPath, [string]$Filter)

    # Get the latest BSP folder matching the filter
    Get-ChildItem -Path $RootPath -Directory -Filter $Filter |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-LatestIfwiZip {
    param ([string]$PackagesPath, [string]$Filter)

    # Get the latest IFWI zip file matching the filter
    Get-ChildItem -Path $PackagesPath -Filter $Filter |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Extract-BinFromZip {
    param (
        [string]$ZipPath,
        [string]$Destination,
        [string]$MatchString
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    } catch {
        Write-Host "Error opening zip file: $_"
        return
    }

    $found = $false

    foreach ($entry in $zip.Entries) {
        if ($entry.FullName -like "*$MatchString*.bin") {
            $outputPath = Join-Path $Destination $entry.Name
            try {
                $entry.ExtractToFile($outputPath, $true)
                Write-Host "Extracted: $($entry.FullName) to $outputPath"
                $found = $true
            } catch {
                Write-Host "Failed to extract $($entry.FullName): $_"
            }
        }
    }

    $zip.Dispose()

    if (-not $found) {
        Write-Host "No matching .bin file found in $ZipPath"
    }
}

# Main Execution Flow

Write-Host "Searching for latest BSP folder in: $IncomingRoot"
$latestBsp = Get-LatestBspFolder -RootPath $IncomingRoot -Filter $BspFilter
if (-not $latestBsp) {
    Write-Host "No BSP folders found matching filter '$BspFilter' in $IncomingRoot"
    exit
}
Write-Host "Latest BSP folder: $($latestBsp.Name)"

$packagesPath = Join-Path $latestBsp.FullName "Packages"
Write-Host "Looking for IFWI zip in: $packagesPath"
$latestZip = Get-LatestIfwiZip -PackagesPath $packagesPath -Filter $ZipFilter
if (-not $latestZip) {
    Write-Host "No IFWI zip files found matching filter '$ZipFilter' in $packagesPath"
    exit
}
Write-Host "Latest IFWI zip: $($latestZip.Name)"

Extract-BinFromZip -ZipPath $latestZip.FullName -Destination $DestinationDir -MatchString $SearchString
