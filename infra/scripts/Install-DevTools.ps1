# ============================================================================
# Install-DevTools.ps1
# PowerShell script to install development tools on Windows Server jumpbox
# ============================================================================

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

$LogPath = "C:\WindowsAzure\Logs\DevToolsInstall.log"
Start-Transcript -Path $LogPath -Append -Force

Write-Host "========================================"
Write-Host "Starting Dev Tools Installation"
Write-Host "Timestamp: $(Get-Date)"
Write-Host "========================================"

# Ensure TLS 1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create temp directory for downloads
$tempDir = "C:\Temp\DevToolsSetup"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}
Set-Location $tempDir

# ============================================================================
# Function: Install via direct download
# ============================================================================
function Install-WithDownload {
    param(
        [string]$Name,
        [string]$Url,
        [string]$FileName,
        [string]$Arguments
    )
    
    Write-Host ""
    Write-Host "[$Name] Starting installation..."
    
    try {
        $filePath = Join-Path $tempDir $FileName
        
        Write-Host "[$Name] Downloading from: $Url"
        Invoke-WebRequest -Uri $Url -OutFile $filePath -UseBasicParsing -ErrorAction Stop
        
        if (Test-Path $filePath) {
            $fileSize = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
            Write-Host "[$Name] Download complete. File size: $fileSize MB"
            
            if ($FileName -like "*.msi") {
                Write-Host "[$Name] Installing MSI..."
                $process = Start-Process msiexec.exe -ArgumentList "/i `"$filePath`" $Arguments" -Wait -PassThru
            } else {
                Write-Host "[$Name] Running installer..."
                $process = Start-Process -FilePath $filePath -ArgumentList $Arguments -Wait -PassThru
            }
            
            Write-Host "[$Name] Installer exit code: $($process.ExitCode)"
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
            Write-Host "[$Name] Installation completed."
            return $true
        } else {
            Write-Host "[$Name] Download failed - file not found."
            return $false
        }
    } catch {
        Write-Host "[$Name] Installation failed: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# Install Azure CLI
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Installing Azure CLI"
Write-Host "========================================"

Install-WithDownload `
    -Name "Azure CLI" `
    -Url "https://aka.ms/installazurecliwindows" `
    -FileName "AzureCLI.msi" `
    -Arguments "/quiet /norestart"

# ============================================================================
# Install Visual Studio Code
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Installing Visual Studio Code"
Write-Host "========================================"

Install-WithDownload `
    -Name "VS Code" `
    -Url "https://update.code.visualstudio.com/latest/win32-x64/stable" `
    -FileName "VSCodeSetup.exe" `
    -Arguments "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath"

# ============================================================================
# Install Git
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Installing Git"
Write-Host "========================================"

Install-WithDownload `
    -Name "Git" `
    -Url "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe" `
    -FileName "GitSetup.exe" `
    -Arguments "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS"

# ============================================================================
# Install PowerShell 7
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Installing PowerShell 7"
Write-Host "========================================"

Install-WithDownload `
    -Name "PowerShell 7" `
    -Url "https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-x64.msi" `
    -FileName "PowerShell7.msi" `
    -Arguments "/quiet /norestart"

# ============================================================================
# Install Microsoft Edge (if not present)
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Installing Microsoft Edge"
Write-Host "========================================"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    Install-WithDownload `
        -Name "Microsoft Edge" `
        -Url "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/d87a3bbd-7fe5-4ec3-b806-293cca78b363/MicrosoftEdgeEnterpriseX64.msi" `
        -FileName "MicrosoftEdge.msi" `
        -Arguments "/quiet /norestart"
} else {
    Write-Host "[Microsoft Edge] Already installed, skipping."
}

# ============================================================================
# Install Google Chrome
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Installing Google Chrome"
Write-Host "========================================"

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    Install-WithDownload `
        -Name "Google Chrome" `
        -Url "https://dl.google.com/chrome/install/GoogleChromeStandaloneEnterprise64.msi" `
        -FileName "GoogleChrome.msi" `
        -Arguments "/quiet /norestart"
} else {
    Write-Host "[Google Chrome] Already installed, skipping."
}

# ============================================================================
# Install Python
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Installing Python"
Write-Host "========================================"

Install-WithDownload `
    -Name "Python" `
    -Url "https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe" `
    -FileName "PythonSetup.exe" `
    -Arguments "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"

# ============================================================================
# Create Desktop Shortcuts
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Creating Desktop Shortcuts"
Write-Host "========================================"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    
    # Azure AI Foundry shortcut
    $shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Azure AI Foundry.url")
    $shortcut.TargetPath = "https://ai.azure.com"
    $shortcut.Save()
    Write-Host "[Shortcut] Created Azure AI Foundry shortcut"
    
    # Azure Portal shortcut
    $shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Azure Portal.url")
    $shortcut.TargetPath = "https://portal.azure.com"
    $shortcut.Save()
    Write-Host "[Shortcut] Created Azure Portal shortcut"
    
} catch {
    Write-Host "[Shortcuts] Failed to create shortcuts: $($_.Exception.Message)"
}

# ============================================================================
# Download and Extract Lab Files
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Downloading Lab Files"
Write-Host "========================================"

try {
    $labFilesUrl = "https://github.com/koenraadhaedens/azd-Azure-AI-Foundry-hub-and-project/archive/refs/heads/main.zip"
    $labFilesZip = Join-Path $tempDir "labfiles.zip"
    $labFilesDestination = "C:\LabFiles"
    
    Write-Host "[Lab Files] Downloading from: $labFilesUrl"
    Invoke-WebRequest -Uri $labFilesUrl -OutFile $labFilesZip -UseBasicParsing -ErrorAction Stop
    
    if (Test-Path $labFilesZip) {
        $fileSize = [math]::Round((Get-Item $labFilesZip).Length / 1MB, 2)
        Write-Host "[Lab Files] Download complete. File size: $fileSize MB"
        
        # Create destination folder
        if (-not (Test-Path $labFilesDestination)) {
            New-Item -ItemType Directory -Path $labFilesDestination -Force | Out-Null
        }
        
        # Extract zip file
        Write-Host "[Lab Files] Extracting to: $labFilesDestination"
        Expand-Archive -Path $labFilesZip -DestinationPath $labFilesDestination -Force
        
        # Move contents from nested folder to root (GitHub adds repo-branch folder)
        $nestedFolder = Get-ChildItem -Path $labFilesDestination -Directory | Select-Object -First 1
        if ($nestedFolder) {
            Get-ChildItem -Path $nestedFolder.FullName | Move-Item -Destination $labFilesDestination -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $nestedFolder.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "[Lab Files] Extraction complete."
        
        # Create VS Code shortcut to open Lab Files folder
        Write-Host "[Lab Files] Creating VS Code shortcut on desktop..."
        $vsCodePath = "C:\Program Files\Microsoft VS Code\Code.exe"
        if (Test-Path $vsCodePath) {
            $WshShell = New-Object -ComObject WScript.Shell
            $shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Lab Files (VS Code).lnk")
            $shortcut.TargetPath = $vsCodePath
            $shortcut.Arguments = "`"$labFilesDestination`""
            $shortcut.WorkingDirectory = $labFilesDestination
            $shortcut.Description = "Open Lab Files in VS Code"
            $shortcut.IconLocation = "$vsCodePath,0"
            $shortcut.Save()
            Write-Host "[Lab Files] VS Code shortcut created on desktop."
        } else {
            Write-Host "[Lab Files] VS Code not found, skipping shortcut creation."
        }
        
        Remove-Item $labFilesZip -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "[Lab Files] Download failed - file not found."
    }
} catch {
    Write-Host "[Lab Files] Failed to download/extract lab files: $($_.Exception.Message)"
}

# ============================================================================
# Cleanup
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Cleanup"
Write-Host "========================================"

Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Temporary files cleaned up."

# ============================================================================
# Summary
# ============================================================================
Write-Host ""
Write-Host "========================================"
Write-Host "Installation Summary"
Write-Host "========================================"

$installed = @()
$notInstalled = @()

# Check installations
if (Test-Path "C:\Program Files\Microsoft\Azure CLI\wbin\az.cmd") { $installed += "Azure CLI" } else { $notInstalled += "Azure CLI" }
if (Test-Path "C:\Program Files\Microsoft VS Code\Code.exe") { $installed += "VS Code" } else { $notInstalled += "VS Code" }
if (Test-Path "C:\Program Files\Git\cmd\git.exe") { $installed += "Git" } else { $notInstalled += "Git" }
if (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe") { $installed += "PowerShell 7" } else { $notInstalled += "PowerShell 7" }
if (Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe") { $installed += "Microsoft Edge" } else { $notInstalled += "Microsoft Edge" }
if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") { $installed += "Google Chrome" } else { $notInstalled += "Google Chrome" }
if (Test-Path "C:\Program Files\Python312\python.exe") { $installed += "Python" } else { $notInstalled += "Python" }
if (Test-Path "C:\LabFiles") { $installed += "Lab Files" } else { $notInstalled += "Lab Files" }

Write-Host ""
Write-Host "Installed:"
foreach ($item in $installed) {
    Write-Host "  [OK] $item"
}

if ($notInstalled.Count -gt 0) {
    Write-Host ""
    Write-Host "Not Installed:"
    foreach ($item in $notInstalled) {
        Write-Host "  [--] $item"
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "Dev Tools Installation Complete!"
Write-Host "Timestamp: $(Get-Date)"
Write-Host "========================================"

Stop-Transcript

# Always exit with success - installations are best effort
exit 0
