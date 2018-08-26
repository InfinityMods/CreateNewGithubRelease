# Script for creating new Github Release

1. Open <https://github.com/settings/tokens>, and create "personal access token" with "public_repo" privilege, it's not you password, you can revoke it at any time

<https://image.prntscr.com/image/18IfQmdxRimt3emiwNLmdA.png>
<https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line>

2. Save it to "CreateNewGithubRelease-APIKey.txt" file you HOME directory, this way it won't be ever committed to repo by accident:

```code
Win: C:\Users\<username>
mac: /Users/<username>
Lin: <root>/home/<username>
```

3. Put CreateNewGithubRelease.ps1 and CreateNewGithubRelease.bat inside man mod directory, same where package_mod.bat is

4. Prepare assets via package_mod.bat, wait until archives are created with proper names:

```code
CreateNewGithubRelease-$tp2Version.exe
mac-CreateNewGithubRelease-$tp2Version.tar
lin-CreateNewGithubRelease-$tp2Version.tar
```

5. Run CreateNewGithubRelease.bat