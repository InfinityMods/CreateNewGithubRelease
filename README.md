# Script for creating new Github release with optional assets

## Features:
- prevent creating new release if the same release already exist
- prevent creating new release if there are uncommitted file modifications
- checking of the mod "VERSION" keyword, prevent creating '2.1.3' release when you mod version is '2.1.2'
- release description can be edited before creating new release
- initial release description is generated from commit messages between two latest tags

## Requirements:
Windows 10 - [Git](https://git-scm.com/download/win)  
Windows 7/8.1 - [Git](https://git-scm.com/download/win), [.NET Framework 4.5.2](https://www.microsoft.com/net/download/dotnet-framework-runtime) or above and [Powershell 5.1](https://docs.microsoft.com/en-us/powershell/wmf/5.1/install-configure)/[Powershell 6](https://github.com/PowerShell/PowerShell/releases/latest)  
macOS - [Git](https://git-scm.com/download/mac) and [Powershell 6](https://github.com/PowerShell/PowerShell/releases/latest)  
Linux - [Git](https://git-scm.com/download/linux) and [Powershell 6](https://github.com/PowerShell/PowerShell/releases/latest) 

## Installation:

1. Download and extract this repository, move everything from 'ModRelease-master' folder directly into the folder where you keep all other top-level mod folders.

1. Open <https://github.com/settings/tokens>, and create ["personal access token"](https://github.com/settings/tokens/new) with "public_repo" privilege, it's not you password, you can revoke it at any time, more info: <https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line>.

1. Save it to "#ModRelease-Github-Key-Example.txt" file and rename it to #ModRelease-Github-Key.txt

1. Put #ModRelease.bat inside mod top-level directory, use the included mod example as reference.

## Usage:
1. Increase mod version inside mod file.

1. Create new commit. Do not create new tag for release, it will be created automatically from mod version and pushed into online repository.

    optional step: create mod packages (release assets), wait until all packages are created with proper names:

    ```code
    ModID-version.exe
    ModID-version.iemod
    ModID-version.zip
    ```

3. Run #ModRelease.bat and follow further instructions.
