# デスクトップに「楽配くん 設定」ショートカットを作成
$WshShell = New-Object -ComObject WScript.Shell
$Desktop = [Environment]::GetFolderPath("Desktop")
$Shortcut = $WshShell.CreateShortcut("$Desktop\楽配くん 設定.lnk")

$ahkPath = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\AutoHotkey.exe" -ErrorAction SilentlyContinue).'(default)'
if (-not $ahkPath) {
    $ahkPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    if (-not (Test-Path $ahkPath)) { $ahkPath = "C:\Program Files\AutoHotkey\v1.1\AutoHotkey.exe" }
}

$scriptPath = Join-Path $PSScriptRoot "rakuhai-settings.ahk"
$Shortcut.TargetPath = $ahkPath
$Shortcut.Arguments = "`"$scriptPath`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Description = "楽配くん 参照用復元の設定画面"
$Shortcut.Save()

Write-Host "デスクトップに「楽配くん 設定」ショートカットを作成しました。"
