#!/bin/sh
command_path=$(cd "$(dirname "$0")"; pwd)
cd "$command_path"
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "..\#ModRelease\#ModRelease.ps1" "$command_path"
exit 0
