# 楽配くん 自動バックアップ復元ツール

楽配くん10の参照用データを、本店の自動バックアップから毎日自動で復元するAutoHotkeyスクリプト。

## 必要なもの

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/)
- 楽配くん10（デスクトップに「楽配くん参照用」ショートカットがあること）

## ファイル構成

| ファイル | 説明 |
|----------|------|
| `rakuhai-auto-restore.ahk` | メインの自動復元スクリプト |
| `rakuhai-settings.ahk` | 設定画面（GUI） |
| `rakuhai-config.ini` | 設定ファイル |
| `rakuhai-pos.txt` | 画面座標（初回実行時に自動生成） |
| `rakuhai-restore-log.txt` | 実行ログ |
| `別PC用セットアップ手順.md` | 別PCへ渡すときの手順・注意点 |
| `楽配くん自動化のノウハウと振り返り.md` | 言語選定・設計の教訓（別の自動化でも参照可） |

## 使い方

### 初回セットアップ

1. AutoHotkey v2 をインストール（`install-autohotkey-v2.ps1` を実行）
2. `rakuhai-auto-restore.ahk` をダブルクリック
3. 画面の指示に従って、各ボタンの位置をマウスで指定（5箇所）
4. 座標が `rakuhai-pos.txt` に保存される

### 手動実行

`rakuhai-auto-restore.ahk` をダブルクリック

### 設定画面

`rakuhai-settings.ahk` をダブルクリックで設定画面を開く

- 自動確認ON/OFF（復元ダイアログを自動で「はい」）
- スケジュール設定（毎日○時に自動実行）
- PC使用中の動作（スキップ/そのまま実行）

### 別のPCで使う場合

**→ 詳しくは `別PC用セットアップ手順.md` を参照してください。**（渡す人・受け取る人向けの手順と注意点をまとめてあります。）

1. このフォルダをコピー（または GitHub から取得）
2. `rakuhai-pos.txt` を削除（座標は画面ごとに異なる）
3. `rakuhai-auto-restore.ahk` を実行して座標を再設定

## ライセンス

MIT
