# ============================================================================
# Install-DevTools.ps1
# PowerShell script to install development tools on Windows Server jumpbox
# ============================================================================

param(
    [string]$LogPath = "C:\WindowsAzure\Logs\DevToolsInstall.log"
)

Start-Transcript -Path $LogPath -Append -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Dev Tools Installation" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

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
    
    Write-Host "`n[$Name] Starting installation via direct download..." -ForegroundColor Yellow
    
    try {
        $filePath = Join-Path $tempDir $FileName
        
        Write-Host "[$Name] Downloading from: $Url"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $filePath -UseBasicParsing -ErrorAction Stop
        
        if (Test-Path $filePath) {
            Write-Host "[$Name] Download complete. File size: $((Get-Item $filePath).Length / 1MB) MB"
            
            if ($FileName -like "*.msi") {
                Write-Host "[$Name] Installing MSI..."
                $process = Start-Process msiexec.exe -ArgumentList "/i `"$filePath`" $Arguments" -Wait -PassThru -NoNewWindow
            } else {
                Write-Host "[$Name] Running installer..."
                $process = Start-Process -FilePath $filePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
            }
            
            Write-Host "[$Name] Installer exit code: $($process.ExitCode)"
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
            Write-Host "[$Name] Installation completed." -ForegroundColor Green
            return $true
        } else {
            Write-Host "[$Name] Download failed - file not found." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[$Name] Installation failed: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# Install Azure CLI
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installing Azure CLI" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Install-WithDownload `
    -Name "Azure CLI" `
    -Url "https://aka.ms/installazurecliwindows" `
    -FileName "AzureCLI.msi" `
    -Arguments "/quiet /norestart"

# ============================================================================
# Install Visual Studio Code
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installing Visual Studio Code" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Install-WithDownload `
    -Name "VS Code" `
    -Url "https://update.code.visualstudio.com/latest/win32-x64/stable" `
    -FileName "VSCodeSetup.exe" `
    -Arguments "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath"

# ============================================================================
# Install Git
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installing Git" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Install-WithDownload `
    -Name "Git" `
    -Url "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe" `
    -FileName "GitSetup.exe" `
    -Arguments "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`""

# ============================================================================
# Install PowerShell 7
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installing PowerShell 7" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Install-WithDownload `
    -Name "PowerShell 7" `
    -Url "https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-x64.msi" `
    -FileName "PowerShell7.msi" `
    -Arguments "/quiet /norestart ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1"

# ============================================================================
# Install Microsoft Edge (if not present)
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installing Microsoft Edge" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    Install-WithDownload `
        -Name "Microsoft Edge" `
        -Url "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/d87a3bbd-7fe5-4ec3-b806-293cca78b363/MicrosoftEdgeEnterpriseX64.msi" `
        -FileName "MicrosoftEdge.msi" `
        -Arguments "/quiet /norestart"
} else {
    Write-Host "[Microsoft Edge] Already installed, skipping." -ForegroundColor Green
}

# ============================================================================
# Install Google Chrome
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installing Google Chrome" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    Install-WithDownload `
        -Name "Google Chrome" `
        -Url "https://dl.google.com/chrome/install/GoogleChromeStandaloneEnterprise64.msi" `
        -FileName "GoogleChrome.msi" `
        -Arguments "/quiet /norestart"
} else {
    Write-Host "[Google Chrome] Already installed, skipping." -ForegroundColor Green
}

# ============================================================================
# Install Python
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Installing Python" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Install-WithDownload `
    -Name "Python" `
    -Url "https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe" `
    -FileName "PythonSetup.exe" `
    -Arguments "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"

# ============================================================================
# Create Desktop Shortcuts
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Creating Desktop Shortcuts" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    $WshShell = New-Object -ComObject WScript.Shell
    
    # Azure AI Foundry shortcut
    $shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Azure AI Foundry.url")
    $shortcut.TargetPath = "https://ai.azure.com"
    $shortcut.Save()
    Write-Host "[Shortcut] Created Azure AI Foundry shortcut" -ForegroundColor Green
    
    # Azure Portal shortcut
    $shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Azure Portal.url")
    $shortcut.TargetPath = "https://portal.azure.com"
    $shortcut.Save()
    Write-Host "[Shortcut] Created Azure Portal shortcut" -ForegroundColor Green
    
} catch {
    Write-Host "[Shortcuts] Failed to create shortcuts: $_" -ForegroundColor Red
}

# ============================================================================
# Refresh Environment Variables
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Refreshing Environment Variables" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
Write-Host "Environment PATH refreshed." -ForegroundColor Green

# ============================================================================
# Cleanup
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Temporary files cleaned up." -ForegroundColor Green

# ============================================================================
# Summary
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Installation Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

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

Write-Host "`nInstalled:" -ForegroundColor Green
$installed | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }

if ($notInstalled.Count -gt 0) {
    Write-Host "`nNot Installed:" -ForegroundColor Yellow
    $notInstalled | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Yellow }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Dev Tools Installation Complete!" -ForegroundColor Green
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Stop-Transcript
