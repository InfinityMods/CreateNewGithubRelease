# Script for creating new Github release with optional assets

## Installation:

1. Open <https://github.com/settings/tokens>, and create ["personal access token"](https://github.com/settings/tokens/new) with "public_repo" privilege, it's not you password, you can revoke it at any time, more info: <https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line>

2. Save it to "Github-API-Key-Release.txt" file

3. Move "Github-API-Key-Release.txt" file you HOME directory, this way it won't be ever committed to repo by accident:

```code
Win: C:\Users\<username>\Github-API-Key-Release.txt
mac: /Users/<username>/Github-API-Key-Release.txt
Lin: <root>/home/<username>/Github-API-Key-Release.txt
```

4. Put #ModRelease.ps1 and #ModRelease.bat inside mod top-level directory

## Usage:
1. Prepare assets, wait until packages are created with proper names:

```code
ModId-$tp2Version.exe
ModId-$tp2Version.iemp
ModId-$tp2Version.zip
mac-ModId-$tp2Version.zip
lin-ModId-$tp2Version.zip
```

2. Run #ModRelease.bat and follow instructions