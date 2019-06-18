# Script for creating new Github release with optional assets

1. Open <https://github.com/settings/tokens>, and create ["personal access token"](https://github.com/settings/tokens/new) with "public_repo" privilege, it's not you password, you can revoke it at any time

<https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line>

2. Save it to "Github-API-Key-Release.txt" file

3. Move "Github-API-Key-Release.txt" file you HOME directory, this way it won't be ever committed to repo by accident:

```code
Win: C:\Users\<username>\Github-API-Key-Release.txt
mac: /Users/<username>/Github-API-Key-Release.txt
Lin: <root>/home/<username>/Github-API-Key-Release.txt
```

4. Put #ModRelease.ps1 and #ModRelease.bat inside man mod directory, same where package_mod.bat is

5. Prepare assets via package_mod.bat, wait until archives are created with proper names:

```code
ModId-$tp2Version.exe
mac-ModId-$tp2Version.zip
lin-ModId-$tp2Version.zip
```

6. Run #ModRelease.bat
