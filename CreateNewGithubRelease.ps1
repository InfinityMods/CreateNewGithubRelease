
function New-GithubReleaseDescription {

    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.StartPosition = 'CenterScreen'
    $form.Height = '600'
    $form.Width = '800'

    $button = New-Object System.Windows.Forms.Button
    $button.Text = 'Save'
    $button.DialogResult = 'Ok'
    $button.Dock = 'bottom'
    $form.Controls.Add( $button )
    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCAncel.Text = 'Cancel'
    $buttonCancel.DialogResult = 'Cancel'
    $buttonCancel.Dock = 'bottom'
    $form.Controls.Add($buttonCancel)
    $textBox = New-Object System.Windows.Forms.Textbox
    $textBox.Multiline = $true
    $textBox.Dock = 'Fill'
    $form.Controls.Add( $textBox )
    $form.add_load( { $textBox.Select() } )
    if ( $form.ShowDialog() -eq 'Ok' ) {
        $form.BringToFront()
        return $textBox.lines
    } else {
        Write-Host 'Cancelled' -ForegroundColor red
        return $null
    }
}

function Get-IEModVersionLine ($IEMod) {
    if ($IEMod -is [System.IO.FileInfo]) { $IEMod = $IEMod.FullName }
    if ($IEMod -is [PSCustomObject]) { $IEMod = $IEMod.tp2TempFullPath }

    $regexVersion = New-Object System.Text.RegularExpressions.Regex('.*?VERSION(\s*)(|~"|~|"|)(@.+|.+)("~|"|~|)(|\s*)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($line in [System.IO.File]::ReadLines($IEMod)) {
        $line = $line -replace "\/\/(.*)(\n|)"
        if ($line -match "\S" -and $line -notmatch "\/\*[\s\S]*?\*\/") {
            if ($regexVersion.IsMatch($line)) {
                [string]$dataVersionLine = $regexVersion.Matches($line).Groups[3].Value.ToString().trimStart(' ').trimStart('~').trimStart('"').TrimEnd(' ').TrimEnd('~').TrimEnd('"')
                if (!$dataVersionLine) { break } else {
                    return $dataVersionLine
                }
            }
        }
    }
}

# Fix for TLS12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$( try { $script:MyInvocation.MyCommand.Path, $script:psISE.CurrentFile.Fullpath, $script:psEditor.GetEditorContext().CurrentFile.Path, $script:dte.ActiveDocument.FullName } catch { $_ } ) | % { $_ | Split-Path -EA 0 | Set-Location }

# Set this to you Personal access token
$apiKey = Get-Content "$env:USERPROFILE\CreateNewGithubRelease-APIKey.txt"
$repository = (Split-Path ( git config --get remote.origin.url ) -Leaf ) -replace '\.git'
$OrgUser = (Split-Path ( git config --get remote.origin.url ) -Parent ) -replace 'https:\\\\github.com\\'
$username = git config --get user.name

$Token = $username + ':' + $apiKey
$Base64Token = [System.Convert]::ToBase64String( [char[]]$Token )
$Headers = @{ Authorization = 'Basic {0}' -f $Base64Token }

[array]$dataReleases = ( Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases" -Headers $Headers -Method Get ).tag_name

$tp2File = ( Get-ChildItem -Path $modFolder -Filter *.tp2 -Recurse )[0]
$tp2FullPath = (( Get-ChildItem -Path $modFolder -Filter *.tp2 -Recurse )[0] ).FullName
$tp2Version = Get-IEModVersionLine $tp2FullPath
$newTagRelease = $tp2Version -replace "\s+", '_'

Write-Host ""
Write-Host " Github link: $OrgUser\$repository"
Write-Host " tp2 VERSION: $tp2Version"
Write-Host "Last Release: $newTagRelease"
Write-Host ""

$compare = ( $dataReleases | ? { $_ -eq $newTagRelease } )
if ( $compare -eq $newTagRelease ) {
    Write-Host "Release already exist, nothing to do."
    pause
    break
}

Write-Host "Do you want to create new Release: $newTagRelease ?"
Write-Host ""
Read-Host "Press ENTER to continue, Ctrl+c to stop" | Out-Null

if ( [System.Environment]::OSVersion.Platform -eq 'Win32NT') {
    $releaseDescription = New-GithubReleaseDescription
    if ( $null -eq $releaseDescription ) { break }
} else {
    $releaseDescription = Read-Host -Prompt 'Release description'
}

$Body = @{
    tag_name = "$newTagRelease"
    name     = "$($repository) $($newTagRelease)"
    body     = $releaseDescription -join '</br>'
} | ConvertTo-Json

git tag "$newTagRelease" --force
git push origin "$newTagRelease" --force

$json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases" -Headers $Headers -Body $Body -Method POST
$json

# Get a release by tag name
$json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET
$releaseID = $json.id

# Windows
$fileName = "$($repository)-$($tp2Version).exe"
$fullName = Get-Item $fileName -EA 0 | Select-Object -ExpandProperty FullName

if ($fullName) {
    # DELETE existing asset with the same name
    $json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET
    if ( $json.assets.name -eq $fileName ) {
        $assertID = $json.assets.id
        Invoke-RestMethod https://api.github.com/repos/$OrgUser/$repository/releases/assets/$assertID -Headers $Headers -Method DELETE
    }

    $json = Invoke-RestMethod "https://uploads.github.com/repos/$OrgUser/$repository/releases/$releaseID/assets?name=`"$fileName`"" `
            -Headers $Headers -Method POST -ContentType 'application/vnd.microsoft.portable-executable' -InFile "$fullName"

    $json.state
}

# Infinity Enngine Mod Package
$fileName = "$($repository)-$($tp2Version).iemp"
$fullName = Get-Item $fileName -EA 0 | Select-Object -ExpandProperty FullName

if ($fullName) {
    # DELETE existing asset with the same name
    $json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET
    if ( $json.assets.name -eq $fileName ) {
        $assertID = $json.assets.id
        Invoke-RestMethod https://api.github.com/repos/$OrgUser/$repository/releases/assets/$assertID -Headers $Headers -Method DELETE
    }

    $json = Invoke-RestMethod "https://uploads.github.com/repos/$OrgUser/$repository/releases/$releaseID/assets?name=`"$fileName`"" `
        -Headers $Headers -Method POST -ContentType 'application/vnd.microsoft.portable-executable' -InFile "$fullName"

    $json.state
}

# ZIP
$fileName = "$($repository)-$($tp2Version).zip"
$fullName = Get-Item $fileName -EA 0 | Select-Object -ExpandProperty FullName

if ($fullName) {
    # DELETE existing asset with the same name
    $json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET
    if ( $json.assets.name -eq $fileName ) {
        $assertID = $json.assets.id
        Invoke-RestMethod https://api.github.com/repos/$OrgUser/$repository/releases/assets/$assertID -Headers $Headers -Method DELETE
    }

    $json = Invoke-RestMethod "https://uploads.github.com/repos/$OrgUser/$repository/releases/$releaseID/assets?name=`"$fileName`"" `
        -Headers $Headers -Method POST -ContentType 'application/vnd.microsoft.portable-executable' -InFile "$fullName"

    $json.state
}

# Windows ZIP
$fileName = "win-$($repository)-$($tp2Version).iemp"
$fullName = Get-Item $fileName -EA 0 | Select-Object -ExpandProperty FullName

if ($fullName) {
    # DELETE existing asset with the same name
    $json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET
    if ( $json.assets.name -eq $fileName ) {
        $assertID = $json.assets.id
        Invoke-RestMethod https://api.github.com/repos/$OrgUser/$repository/releases/assets/$assertID -Headers $Headers -Method DELETE
    }

    $json = Invoke-RestMethod "https://uploads.github.com/repos/$OrgUser/$repository/releases/$releaseID/assets?name=`"$fileName`"" `
        -Headers $Headers -Method POST -ContentType 'application/vnd.microsoft.portable-executable' -InFile "$fullName"

    $json.state
}

# macOS
$fileName = "osx-$($repository)-$($tp2Version).tar.gz"
$fullName = Get-Item $fileName -EA 0 | Select-Object -ExpandProperty FullName

if ($fullName) {
    # DELETE existing asset with the same name
    $json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET
    if ( $json.assets.name -eq $fileName ) {
        $assertID = $json.assets.id
        Invoke-RestMethod https://api.github.com/repos/$OrgUser/$repository/releases/assets/$assertID -Headers $Headers -Method DELETE
    }

    $json = Invoke-RestMethod "https://uploads.github.com/repos/$OrgUser/$repository/releases/$releaseID/assets?name=`"$fileName`"" `
            -Headers $Headers -Method POST -ContentType 'application/gzip' -InFile "$fullName"

    $json.state
}

# Linux
$fileName = "lin-$($repository)-$($tp2Version).tar.gz"
$fullName = Get-Item $fileName -EA 0 | Select-Object -ExpandProperty FullName

if ($fullName) {
    # DELETE existing asset with the same name
    $json = Invoke-RestMethod "https://api.github.com/repos/$OrgUser/$repository/releases/tags/$newTagRelease" -Headers $Headers -Method GET
    if ( $json.assets.name -eq $fileName ) {
        $assertID = $json.assets.id
        Invoke-RestMethod https://api.github.com/repos/$OrgUser/$repository/releases/assets/$assertID -Headers $Headers -Method DELETE
    }

    $json = Invoke-RestMethod "https://uploads.github.com/repos/$OrgUser/$repository/releases/$releaseID/assets?name=`"$fileName`"" `
            -Headers $Headers -Method POST -ContentType 'application/gzip' -InFile "$fullName"

    $json.state
}