param($ModTopDirectory)

function Get-IEModVersion ($Path) {
    $regexVersion = [Regex]::new('.*?VERSION(\s*)(|~"|~|"|)(@.+|.+)("~|"|~|)(|\s*)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        $line = $line -replace "\/\/(.*)(\n|)"
        if ($line -match "\S" -and $line -notmatch "\/\*[\s\S]*?\*\/") {
            if ($regexVersion.IsMatch($line)) {
                [string]$dataVersionLine = $regexVersion.Matches($line).Groups[3].Value.ToString().trimStart(' ').trimStart('~').trimStart('"').TrimEnd(' ').TrimEnd('~').TrimEnd('"')
                $dataVersionLine
                break
            }
        }
    }
}

function Install-PSAvaloniaModule {
    if ($PSVersionTable.PSVersion.Major -ge 6 -and $PSVersionTable.PSVersion.Minor -ge 2 -or $PSVersionTable.PSVersion.Major -ge 7) {
        # If module is imported say that and do nothing
        if (Get-Module | ? Name -eq 'PSAvalonia') {
            Write-Host "Module 'PSAvalonia' is already imported."
            $true
        } else {
            # If module is not imported, but available on disk then import
            if (Get-Module -ListAvailable | ? Name -eq 'PSAvalonia') {
                Import-Module 'PSAvalonia' -Force -PassThru
            } else {
                # If module is not imported, not available on disk, but is in online gallery then install and import
                if (Find-Module -Name 'PSAvalonia' | Where-Object { $_.Name -eq 'PSAvalonia' }) {
                    Install-Module -Name 'PSAvalonia' -Force -Scope CurrentUser
                    Import-Module 'PSAvalonia' -Force -PassThru
                } else {
                    # If module is not imported, not available and not in online gallery then abort
                    Write-Host "Module 'PSAvalonia' not imported, not available and not in online gallery, exiting."
                    $false
                }
            }
        }
    } else {
        # only for PS 6+
        $false
    }
}

function New-GithubReleaseDescription {
    param($ReleaseDescription)
    Add-Type -AssemblyName System.Windows.Forms

    $form = New-Object System.Windows.Forms.Form
    $form.StartPosition = 'CenterScreen'
    $form.Height = '600'
    $form.Width = '400'

    $button = New-Object System.Windows.Forms.Button
    $button.Location = [System.Drawing.Point]::new(297, 526)
    $button.Text = 'Save'
    $button.DialogResult = 'Ok'
    $button.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom, [System.Windows.Forms.AnchorStyles]::Right

    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCancel.Location = [System.Drawing.Point]::new(12, 526)
    $buttonCAncel.Text = 'Cancel'
    $buttonCancel.DialogResult = 'Cancel'
    $buttonCancel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom, [System.Windows.Forms.AnchorStyles]::Left

    $textBox = New-Object System.Windows.Forms.Textbox
    $textBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top, [System.Windows.Forms.AnchorStyles]::Bottom, [System.Windows.Forms.AnchorStyles]::Left, [System.Windows.Forms.AnchorStyles]::Right
    $textBox.Multiline = $true
    $textBox.Location = [System.Drawing.Point]::new(12, 12)
    $textBox.Size = [System.Drawing.Size]::new(360, 508)
    $textBox.Text = $ReleaseDescription

    $form.Controls.Add($textBox)
    $form.Controls.Add($button)
    $form.Controls.Add($buttonCancel)
    $form.add_load({ $textBox.Focus() })

    $dialog = $form.ShowDialog()
    $form.BringToFront()
    if ($dialog -eq 'Ok') {
        $textBox.Lines
    }
}

function New-GithubReleaseDescriptionAv {
    [CmdletBinding()]
    param($ReleaseDescription)
    begin {
        if (!(Get-Module -All -ListAvailable -Name PSAvalonia)) {
            try {
                Install-Module -Name PSAvalonia -Scope CurrentUser
            } catch {
                $_
            }
        } else {
            $remoteVersion = [Version]::parse((Find-Module -Name 'PSAvalonia').Version)
            $localVersion = (Get-Module -All -ListAvailable -Name PSAvalonia -PSEdition Core).Version
            if ($remoteVersion -ne $localVersion) {
                Update-Module psavalonia -Force
            }
        }
    }
    process {
        Import-Module PSAvalonia

        $Xaml =
        '<Window xmlns="https://github.com/avaloniaui"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            mc:Ignorable="d"
            x:Class="avaloniaui.MainWindow"
            Name= "wRD" Title="Release description:" Height="800" Width="600">
            <Grid>
                <Button Name="bSave" IsDefault="True" Content="Save" VerticalAlignment="Bottom" HorizontalAlignment="Right"/>
                <Button Name="bCancel" Content="Cancel" VerticalAlignment="Bottom" HorizontalAlignment="Left"/>
                <TextBox Name="tbRD" HorizontalAlignment="Left" TextWrapping="NoWrap" VerticalAlignment="Top" Height="760" Width="600" />
            </Grid>
        </Window>'

        $window = ConvertTo-AvaloniaWindow -Xaml $Xaml
        $bCancel = Find-AvaloniaControl -Name 'bCancel' -Window $Window
        $bSave = Find-AvaloniaControl -Name 'bSave' -Window $Window
        $tbRD = Find-AvaloniaControl -Name 'tbRD' -Window $Window
        $tbRD.Text = $ReleaseDescription

        $window.add_Activated({ $tbRD.Focus() })
        $bSave.add_Click({ $window.Close() })
        $bCancel.add_Click({ $tbRD.Text = $null ; $window.Close() })

        Show-AvaloniaWindow -Window $Window -Verbose
    }
    end {
        $tbRD.Text
    }
}

function Update-GithubReleaseAsset {
    param($FullName, $OrgUser, $Repository, $ReleaseID)
    if ($FullName) {
        # DELETE existing asset with the same name
        $json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET
        $fileName = Split-Path $FullName -Leaf
        if ($json.assets.name -eq $fileName) {
            $assertID = $json.assets.id
            Invoke-RestMethod https://api.github.com/repos/$OrgUser/$repository/releases/assets/$assertID -Headers $Headers -Method DELETE
        }

        $json = Invoke-RestMethod "https://uploads.github.com/repos/$OrgUser/$repository/releases/$releaseID/assets?name=`"$fileName`"" `
            -Headers $Headers -Method POST -ContentType 'application/gzip' -InFile "$fullName"
        Write-Host "$fileName $json.state"
    }
}

function New-UniversalModPackage {
    [CmdletBinding()]
    param ($ModTopDirectory)

    begin {

        $ModMainFile = (Get-ChildItem -Path $ModTopDirectory -Recurse -Depth 1 -Include "*.tp2", "*.tp3")[0]
        $ModID = $ModMainFile.BaseName -replace 'setup-'

        $weiduExeBaseName = "Setup-$ModID"

        $ModVersion = Get-IEModVersion -Path $ModMainFile.FullName
        if ($null -eq $ModVersion -or $ModVersion -eq '') { $ModVersion = '0.0.0' }

        $iniData = try { Get-Content $ModTopDirectory\$ModID\$ModID.ini -EA 0 } catch { }
        if ($iniData) {
            $ModDisplayName = (($iniData | ? { $_ -notlike "*#*" -and $_ -like "Name*=*" }) -split '=')[1].TrimStart(' ').TrimEnd(' ')

            # Github release asset name limitation
            $PackageName = "$($ModDisplayName -replace "\s",'-')-$($ModVersion -replace "\s",'-')"

        } else {
            $PackageName = "$($ModID -replace "\s",'-')-$($ModVersion -replace "\s",'-')"
        }

        # cleanup old files
        Remove-Item -Path "$ModTopDirectory\*.iemod" -Force -EA 0 | Out-Null

        $outIEMod = "$ModID-iemod"
        $outZip = "$ModID-zip"

        # temp dir
        if ($PSVersionTable.PSEdition -eq 'Desktop' -or $isWindows) {
            $tempDir = Join-path -Path $env:TEMP -ChildPath (Get-Random)
        } else {
            $tempDir = Join-path -Path '/tmp' -ChildPath (Get-Random)
        }

        Remove-Item $tempDir -Recurse -Force -EA 0 | Out-Null
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        New-Item -Path $tempDir\$outIEMod\$ModID -ItemType Directory -Force | Out-Null
        New-Item -Path $tempDir\$outZip\$ModID -ItemType Directory -Force | Out-Null

    }
    process {
        $regexAny = ".*", "*.7z", "*.bak", "*.bat", "*.iemod", "*.rar", "*.tar*", "*.tmp", "*.temp", "*.zip", 'backup', 'bgforge.ini', 'Thumbs.db', 'ehthumbs.db', '__macosx', '$RECYCLE.BIN'
        $excludedAny = Get-ChildItem -Path $ModTopDirectory\$ModID -Recurse -Include $regexAny

        #iemod package
        Copy-Item -Path $ModTopDirectory\$ModID\* -Destination $tempDir\$outIEMod\$ModID -Recurse -Exclude $regexAny | Out-Null

        Write-Host "Creating $PackageName.iemod" -ForegroundColor Green

        Compress-Archive -Path $tempDir\$outIEMod\* -DestinationPath "$ModTopDirectory\$PackageName.zip" -Force -CompressionLevel Optimal | Out-Null
        Rename-Item -Path "$ModTopDirectory\$PackageName.zip" -NewName "$PackageName.iemod" -Force | Out-Null

        # zip package
        Copy-Item -Path $ModTopDirectory\$ModID\* -Destination $tempDir\$outZip\$ModID -Recurse -Exclude $regexAny | Out-Null

        # get latest weidu version
        $datalastRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/weiduorg/weidu/releases/latest' -Headers $Headers -Method Get
        $weiduWinUrl = $datalastRelease.assets | ? name -Match 'Windows' | Select-Object -ExpandProperty browser_download_url
        $weiduMacUrl = $datalastRelease.assets | ? name -Match 'Mac' | Select-Object -ExpandProperty browser_download_url

        Invoke-WebRequest -Uri $weiduWinUrl -Headers $Headers -OutFile "$tempDir\WeiDU-Windows.zip" -PassThru | Out-Null
        Expand-Archive -Path "$tempDir\WeiDU-Windows.zip" -DestinationPath "$tempDir\" | Out-Null

        Invoke-WebRequest -Uri $weiduMacUrl -Headers $Headers -OutFile "$tempDir\WeiDU-Mac.zip" -PassThru | Out-Null
        Expand-Archive -Path "$tempDir\WeiDU-Mac.zip" -DestinationPath "$tempDir\" | Out-Null

        # Copy latest WeiDU versions
        Copy-Item "$tempDir\WeiDU-Windows\bin\amd64\weidu.exe" "$tempDir\$outZip\$weiduExeBaseName.exe" | Out-Null
        Copy-Item "$tempDir\WeiDU-Mac\bin\amd64\weidu" "$tempDir\$outZip\$($weiduExeBaseName.tolower())" | Out-Null

        # Create .command script
        'cd "${0%/*}"' + "`n" + 'ScriptName="${0##*/}"' + "`n" + './${ScriptName%.*}' + "`n" | Set-Content -Path "$tempDir\$outZip\$($weiduExeBaseName.tolower()).command" | Out-Null

        Write-Host "Creating $PackageName.zip" -ForegroundColor Green

        Compress-Archive -Path $tempDir\$outZip\* -DestinationPath "$ModTopDirectory\$PackageName.zip" -Force -CompressionLevel Optimal | Out-Null
    }
    end {
        if ($excludedAny) {
            Write-Warning "Excluded items fom the package:"
            $excludedAny.FullName.Substring($ModTopDirectory.length) | Write-Warning
            pause
        }
    }
}

# Fix for TLS12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# script directory as initial execution location
$(try { $script:MyInvocation.MyCommand.Path, $script:psISE.CurrentFile.Fullpath, $script:psEditor.GetEditorContext().CurrentFile.Path, $script:dte.ActiveDocument.FullName } catch { $_ }) | % { $_ | Split-Path -EA 0 | Set-Location }

if ($ModTopDirectory) {
    Set-Location $ModTopDirectory
} else {
    Write-Host "Cannot determine mod top-level folder."
    break
}

if (! (Get-Item '..\#ModRelease\#ModRelease-Github-Key.txt')) {
    Rename-Item '..\#ModRelease\#ModRelease-Github-Key-Example.txt' '..\#ModRelease\#ModRelease-Github-Key.txt' | Out-Null
}

# get Personal Access Token
$apiKey = Get-Content "..\#ModRelease\#ModRelease-Github-Key.txt" -TotalCount 1

if ($apiKey.TrimStart(' ').TrimEnd(' ').Length -ne 40) {
    $apiKey.Length
    Write-Host "API-KEY length is not 40 characters, please check the first line of #ModRelease-Github-Key.txt"
    pause
    break
}

$repository = (Split-Path (git config --get remote.origin.url) -Leaf) -replace '\.git'
$OrgUser = ((Split-Path (git config --get remote.origin.url) -Parent) -replace 'https:\\\\github.com\\') -replace 'https:\/\/github.com\/'
$username = git config --get user.name

$Token = $username + ':' + $apiKey
$Base64Token = [System.Convert]::ToBase64String([char[]]$Token)
$Headers = @{ Authorization = 'Basic {0}' -f $Base64Token }

[array]$dataReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/$OrgUser/$repository/releases" -Headers $Headers -Method Get
$dataTags = ($dataReleases | Sort-Object -Property published_at -Descending).tag_name
if ($dataTags) { $lastRelease = $dataTags[0] }

$ModMainFile = (Get-ChildItem -Path $ModTopDirectory -Recurse -Depth 1 -Include "*.tp2", "*.tp3")[0]
$ModID = $ModMainFile.BaseName -replace 'setup-'
$ModVersion = Get-IEModVersion -Path $ModMainFile.FullName
if ($null -eq $ModVersion -or $ModVersion -eq '') { $ModVersion = '0.0.0' }

$PackageName = "$ModID-$ModVersion"

$newTagRelease = $ModVersion -replace "\s+", '_'

Write-Host
Write-Host " Github link: $OrgUser/$repository"
Write-Host " mod VERSION: $ModVersion"
if ($lastRelease) {
    Write-Host "Last Release: $lastRelease"
}
Write-Host

if ($dataTags) {
    $compare = ($dataTags | ? { $_ -eq $newTagRelease })
    if ($compare -eq $newTagRelease) {
        Write-Host "Release already exist, nothing to do."
        pause
        break
    }
} else {
    Write-Host "No online releases detected."
}

Start-Process -FilePath 'git' -ArgumentList 'update-index --refresh' -Wait -NoNewWindow
$LocalChanges = (Start-Process -FilePath 'git' -ArgumentList 'diff-index --quiet HEAD --' -Wait -NoNewWindow -PassThru).ExitCode
if ($LocalChanges) {
    Write-Host "You have uncommitted changes, please commit or revert them before making new release."
    pause
    break
}

Write-Host "Do you want to create new Release: $newTagRelease ?"
Write-Host
Read-Host "Press ENTER to continue, Ctrl+c to stop" | Out-Null

git tag "$newTagRelease" --force
git push origin "$newTagRelease" --force

$gitLastTag = git describe --tags
$gitPrevTag = git describe --abbrev=0 --tags $(git rev-list --tags --skip=1 --max-count=1)
$dataGitLog = git log --format=%B "$gitLastTag"..."$gitPrevTag" | ? { $_ -match '\w' }
$dataGitLog = $dataGitLog -join "`r`n"

if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
    $releaseDescription = New-GithubReleaseDescription -ReleaseDescription $dataGitLog
    if ($null -eq $releaseDescription) {
        Write-Host "Release description was empty, nothing to do."
        pause
        break
    }
} elseif (Install-PSAvaloniaModule) {
    $releaseDescription = New-GithubReleaseDescriptionAv -ReleaseDescription $dataGitLog -EA 0
    if ($null -eq $releaseDescription) {
        $releaseDescription = Read-Host -Prompt 'Release description'
    }
} else {
    Write-Host "Release description was empty, nothing to do."
    pause
    break
}

$Body = @{
    tag_name = "$newTagRelease"
    name     = "$($repository) $($newTagRelease)"
    body     = $releaseDescription -join '</br>'
} | ConvertTo-Json

try {
    $json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases" -Headers $Headers -Body $Body -Method POST
    Write-Host
    Write-Host "New Release created: $($json.name)"
    Write-Host
} catch { $_ }

$ErrorActionPreference = 'Stop'
# Get a release by tag name
$json = try { Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET } catch { $_ }
$ErrorActionPreference = 'Continue'

$releaseID = $json.id

New-UniversalModPackage -ModTopDirectory $ModTopDirectory

# Universal Mod Package, Zip Package, Windows Self-Extracting WinRar Package
$fileName = Get-Item -Path "$PackageName.iemod", "$PackageName.zip" -EA 0

$fileName | % {
    $fullName = Get-ChildItem $_ -EA 0 | Select-Object -ExpandProperty FullName
    if ($FullName) {
        Update-GithubReleaseAsset -FullName $FullName -OrgUser $OrgUser -Repository $repository -ReleaseID $releaseID
    }
}

Write-Host "Finished." -ForegroundColor Green
