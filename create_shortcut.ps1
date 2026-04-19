$ws = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop "Gangster Town Adventures.lnk"
$shortcut = $ws.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "D:\GTA_LITE\GangsterTownAdventures\build\GangsterTownAdventures.exe"
$shortcut.WorkingDirectory = "D:\GTA_LITE\GangsterTownAdventures\build"
$shortcut.Description = "Gangster Town Adventures - Vice City Style"
$shortcut.Save()
Write-Host "Desktop shortcut created at: $shortcutPath"
