


#  1. Variables
$Source = Join-Path $PSScriptRoot "source"
$Destination = "C:\Users\ASUS\Desktop\MyAssignmentApp"
$RegPath = "HKCU:\Software\MyAssignmentApp"
$LogFile = Join-Path $PSScriptRoot "SetupLogs.log"


# 2. Logging function

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"     
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$time [$Level] $Message"

    Write-Host $line
    $currentLog = if ($global:LogFile) { $global:LogFile } elseif ($script:LogFile) { $script:LogFile } else { $LogFile }
    Add-Content -Path $currentLog -Value $line
}


# 3. Create folder
function New-DestinationFolder {
    param([string]$Path)

    try {
        if (Test-Path $Path) {
            Write-Log "Folder already exists: $Path"
        }
        else {
            New-Item -ItemType Directory -Path $Path -ErrorAction Stop | Out-Null
            Write-Log "Folder created: $Path"
        }
        return $true
    }
    catch {
        Write-Log "Could not create folder $Path. $($_.Exception.Message)" "ERROR"
        return $false
    }
}


# 4. Copy files
function Copy-SourceFiles {
    param(
        [string]$From,
        [string]$To
    )

    try {

        if (-not (Test-Path $From)) {
            Write-Log "Source not found: $From" "ERROR"
            return $false
        }

   
        if (-not (New-DestinationFolder -Path $To)) {
            return $false
        }

        Copy-Item -Path "$From\*" -Destination $To -Recurse -Force -ErrorAction Stop
        Write-Log "Files copied from $From to $To"
        return $true
    }
    catch {
        Write-Log "Copy failed. $($_.Exception.Message)" "ERROR"
        return $false
    }
}


# 5. Registry key and value
function New-RegistryEntry {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )

    try {
        
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            Write-Log "Registry key created: $Path"
        }
        else {
            Write-Log "Registry key already exists: $Path"
        }

        
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force -ErrorAction Stop | Out-Null
        Write-Log "Registry value set: $Name = $Value"
        return $true
    }
    catch {
        Write-Log "Registry error. $($_.Exception.Message)" "ERROR"
        return $false
    }
}


#  6. Main part
if ($MyInvocation.InvocationName -ne ".") {

    Write-Log "===== Setup started ====="

    $folderOk = New-DestinationFolder -Path $Destination
    $copyOk = Copy-SourceFiles -From $Source -To $Destination
    $regOk1 = New-RegistryEntry -Path $RegPath -Name "InstallPath" -Value $Destination
    $regOk2 = New-RegistryEntry -Path $RegPath -Name "Version" -Value "1.0"

    if ($folderOk -and $copyOk -and $regOk1 -and $regOk2) {
        Write-Log "===== Setup finished successfully ====="
    }
    else {
        Write-Log "===== Setup finished with errors. Check the log ====="
    }
}