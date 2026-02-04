# =========================
# Cursor Free VIP Installer
# Fork-safe & Future-proof
# =========================

# ---------- Theme ----------
$Theme = @{
    Primary = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'White'
}

# ---------- Logo ----------
$Logo = @"
   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗      ██████╗ ██████╗  ██████╗
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔═══██╗
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝     ██████╔╝██████╔╝██║   ██║
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗     ██╔═══╝ ██╔══██╗██║   ██║
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║     ██║     ██║  ██║╚██████╔╝
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝
"@

# ---------- Styled Output ----------
function Write-Styled {
    param(
        [string]$Message,
        [string]$Color = $Theme.Info,
        [string]$Prefix = ""
    )

    $icon = switch ($Color) {
        $Theme.Success { "[OK]" }
        $Theme.Error   { "[X]" }
        $Theme.Warning { "[!]" }
        default        { "[*]" }
    }

    if ($Prefix) {
        Write-Host "$icon $Prefix :: $Message" -ForegroundColor $Color
    } else {
        Write-Host "$icon $Message" -ForegroundColor $Color
    }
}

# ---------- TLS ----------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---------- GitHub Info ----------
$RepoOwner = "Tegeney"
$RepoName  = "cursor-free-vip"
$ApiUrl    = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"

# ---------- Get Latest Release ----------
function Get-LatestRelease {
    try {
        Invoke-RestMethod -Uri $ApiUrl -Headers @{ "User-Agent" = "PowerShell" }
    }
    catch {
        Write-Styled "Failed to contact GitHub API" $Theme.Error "Error"
        throw "Cannot get latest version"
    }
}

# ---------- Main Installer ----------
function Install-CursorFreeVIP {

    Write-Styled "Checking latest release..." $Theme.Primary "Update"
    $release = Get-LatestRelease

    $version = $release.tag_name
    Write-Styled "Latest version: $version" $Theme.Success "Version"

    # Find Windows EXE (version-agnostic)
    $asset = $release.assets | Where-Object {
        $_.name -match "_windows\.exe$"
    } | Select-Object -First 1

    if (-not $asset) {
        Write-Styled "No Windows executable found in release assets" $Theme.Error "Error"
        throw "Missing executable"
    }

    Write-Styled "Found asset: $($asset.name)" $Theme.Success "Asset"

    $Downloads = Join-Path $env:USERPROFILE "Downloads"
    $ExePath  = Join-Path $Downloads $asset.name

    # Download if not exists
    if (-not (Test-Path $ExePath)) {

        Write-Styled "Downloading..." $Theme.Primary "Download"
        Write-Styled $asset.browser_download_url $Theme.Info "URL"

        Invoke-WebRequest `
            -Uri $asset.browser_download_url `
            -OutFile $ExePath `
            -UseBasicParsing `
            -Headers @{ "User-Agent" = "PowerShell" }

        Write-Styled "Download completed" $Theme.Success "Done"
    }
    else {
        Write-Styled "File already exists" $Theme.Warning "Skip"
    }

    # Run as admin if needed
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Styled "Requesting administrator privileges..." $Theme.Warning "Admin"
        Start-Process $ExePath -Verb RunAs
    }
    else {
        Write-Styled "Launching application..." $Theme.Primary "Run"
        Start-Process $ExePath
    }
}

# ---------- Start ----------
Clear-Host
Write-Host $Logo -ForegroundColor $Theme.Primary
Write-Host "Created by YeongPin (Fork maintained by Tegeney)`n" -ForegroundColor $Theme.Info

try {
    Install-CursorFreeVIP
}
catch {
    Write-Styled $_ $Theme.Error "Fatal"
}

Write-Host "`nPress any key to exit..." -ForegroundColor $Theme.Info
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
