param (
    [Parameter(Mandatory=$true)]
    [string]$IncomingRoot,  # Root path to the Incoming folder

    [Parameter(Mandatory=$true)]
    [string]$DestinationDir,  # Where to extract the .bin file

    [string]$SearchString = "PTL_PR01_XXXX-XXXODCA_CPRF_SED5_01E50692"  # Pattern to match in .bin filename
)

# Function to get the most recently modified BSP folder
function Get-LatestBspFolder {
    param ([string]$RootPath)

    # List all directories, sort by last modified time, and return the latest one
    Get-ChildItem -Path $RootPath -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

# Function to get the latest IFWI zip file from the Packages folder
function Get-LatestIfwiZip {
    param ([string]$PackagesPath)

    # Look for zip files matching the IFWI naming pattern and return the latest one
    Get-ChildItem -Path $PackagesPath -Filter "IFWI_PTLH_A0B0_PSPP_Release_*.zip" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

# Function to extract the .bin file matching the search string from the zip
function Extract-BinFromZip {
    param (
        [string]$ZipPath,
        [string]$Destination,
        [string]$MatchString
    )

    # Load .NET compression library
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Create destination directory if it doesn't exist
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    # Open the zip file for reading
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    $found = $false

    # Loop through each entry in the zip
    foreach ($entry in $zip.Entries) {
        # Check if the entry name contains the search string and ends with .bin
        if ($entry.FullName -like "*$MatchString*.bin") {
            $outputPath = Join-Path $Destination $entry.Name
            $entry.ExtractToFile($outputPath, $true)
            Write-Host "Extracted: $($entry.FullName) to $outputPath"
            $found = $true
        }
    }

    # Close the zip file
    $zip.Dispose()

    if (-not $found) {
        Write-Host "No matching .bin file found in $ZipPath"
    }
}

# Main script execution 

# Step 1: Get the latest BSP folder
$latestBsp = Get-LatestBspFolder -RootPath $IncomingRoot
if (-not $latestBsp) {
    Write-Host "No BSP folders found in $IncomingRoot"
    exit
}
Write-Host "Latest BSP folder: $($latestBsp.Name)"

# Step 2: Get the latest IFWI zip file from the Packages subfolder
$packagesPath = Join-Path $latestBsp.FullName "Packages"
$latestZip = Get-LatestIfwiZip -PackagesPath $packagesPath
if (-not $latestZip) {
    Write-Host "No IFWI zip files found in $packagesPath"
    exit
}
Write-Host "Latest IFWI zip: $($latestZip.Name)"

# Step 3: Extract the matching .bin file
Extract-BinFromZip -ZipPath $latestZip.FullName -Destination $DestinationDir -MatchString $SearchString
