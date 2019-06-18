# Script for creating new Github release with optional assets

## Installation:

1. Download and extract this repository, move everything from 'ModRelease-master' folder directly into extracted mods folder.

1. Open <https://github.com/settings/tokens>, and create ["personal access token"](https://github.com/settings/tokens/new) with "public_repo" privilege, it's not you password, you can revoke it at any time, more info: <https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line>.

1. Save it to "#ModRelease-Github-Key-Example.txt" file and rename it to #ModRelease-Github-Key.txt

1. Put #ModRelease.bat inside mod top-level directory, reffer to included mod example.

## Usage:
1. Increase mod version inside mod file.

2. Create new commit. Do not create new tag for release, it will be created automatically from mod version.

3. Optionally, create assets, wait until all packages are created with proper names:

```code
ModId-$tp2Version.exe
ModId-$tp2Version.iemp
ModId-$tp2Version.zip
```

4. Run #ModRelease.bat and follow further instructions.
