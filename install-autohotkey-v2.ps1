# AutoHotkey v2 インストーラのダウンロードと起動
# 実行: 右クリック → 「PowerShellで実行」 または 管理者で powershell -ExecutionPolicy Bypass -File "install-autohotkey-v2.ps1"

$url = "https://www.autohotkey.com/download/ahk-v2.exe"
$dest = "$env:USERPROFILE\Downloads\ahk-v2.exe"

Write-Host "AutoHotkey v2 をダウンロードしています..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    Write-Host "ダウンロード完了: $dest" -ForegroundColor Green
    Write-Host "インストーラを起動します。画面の指示に従って「Install」を選んでください。" -ForegroundColor Yellow
    Start-Process -FilePath $dest -Wait
    Write-Host "完了しました。" -ForegroundColor Green
s} catch {
    Write-Host "エラー: $_" -ForegroundColor Red
    exit 1
}
f