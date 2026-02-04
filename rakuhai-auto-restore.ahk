#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2

; ========== 信頼性向上のための設定 ==========
SendMode "Event"           ; より確実なイベント送信モード
SetMouseDelay 50           ; マウス操作間の遅延
SetKeyDelay 50             ; キー操作間の遅延
SetWinDelay 200            ; ウィンドウ操作間の遅延
A_CoordModeMouse := "Screen"  ; すべてスクリーン座標で統一

; ログファイル
logFile := A_ScriptDir "\rakuhai-restore-log.txt"

; ログ書き込み関数
WriteLog(message) {
    global logFile
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend timestamp " - " message "`n", logFile
}

; 確実にクリックする関数（移動 → 待機 → クリック → 待機）
ReliableClick(x, y, waitAfter := 500) {
    MouseMove x, y, 10      ; ゆっくり移動（速度10）
    Sleep 200               ; 移動完了を待つ
    Click                   ; 現在位置でクリック
    Sleep 100
    Click                   ; 念のためダブルクリック
    Sleep waitAfter         ; クリック後の待機
}

; 設定ファイルを読む
configPath := A_ScriptDir "\rakuhai-config.ini"
autoConfirm := 0
ifInUse := "Skip"
if FileExist(configPath) {
    try {
        autoConfirm := Integer(IniRead(configPath, "Settings", "AutoConfirm", "0"))
        ifInUse := IniRead(configPath, "Settings", "IfInUse", "Skip")
    }
}

; ========== 座標設定（INI形式で保存・読込） ==========
rakuhaiShortcut := A_Desktop "\楽配くん参照用.lnk"
posFile := A_ScriptDir "\rakuhai-pos.ini"

; 座標を読み込む関数
ReadPos(key, defaultVal := 0) {
    global posFile
    try {
        return Integer(IniRead(posFile, "Coordinates", key, String(defaultVal)))
    } catch {
        return defaultVal
    }
}

; 座標を保存する関数（上書き、重複しない）
SavePos(key, value) {
    global posFile
    IniWrite String(value), posFile, "Coordinates", key
}

; 座標を読み込む
specialScreenX := ReadPos("SpecialX")
specialScreenY := ReadPos("SpecialY")
backupScreenX := ReadPos("BackupX")
backupScreenY := ReadPos("BackupY")
tabScreenX := ReadPos("TabX")
tabScreenY := ReadPos("TabY")
listScreenX := ReadPos("ListX")
listScreenY := ReadPos("ListY")
restoreScreenX := ReadPos("RestoreX")
restoreScreenY := ReadPos("RestoreY")

; ========== メイン処理開始 ==========
WriteLog("========== 復元処理を開始 ==========")

; 1) 楽配くんが既に起動しているかチェック（設定画面・Cursorは除外）
alreadyRunning := false
if WinExist("メインメニュー") {
    alreadyRunning := true
} else {
    ; 「楽配くん」を含むが「参照用復元」「設定」「Cursor」「.md」を含まないウィンドウを探す
    for hwnd in WinGetList() {
        try {
            title := WinGetTitle(hwnd)
            if InStr(title, "楽配くん") && !InStr(title, "参照用復元") && !InStr(title, "設定") && !InStr(title, "Cursor") && !InStr(title, ".md") {
                alreadyRunning := true
                break
            }
        }
    }
}

if alreadyRunning {
    if (ifInUse = "Skip") {
        WriteLog("スキップ: 楽配くんが起動中")
        MsgBox("楽配くんが起動中のため、復元をスキップしました。`n`n手動で閉じてから再実行するか、設定で「そのまま実行」に変更してください。", "楽配くん 自動復元")
        ExitApp
    }
    WriteLog("楽配くん起動中 → そのまま実行")
} else {
    WriteLog("楽配くんを起動")
    Run rakuhaiShortcut
}

; 2) メインメニューが開くまで待つ（設定画面・Cursorは除外）
WriteLog("メインメニューを待機中...")
mainWin := ""
Loop 120 {  ; 最大60秒待つ
    if WinExist("メインメニュー") {
        mainWin := "メインメニュー"
        break
    }
    ; 「楽配くん」を含むが「参照用復元」「設定」「Cursor」「.md」を含まないウィンドウを探す
    for hwnd in WinGetList() {
        try {
            title := WinGetTitle(hwnd)
            if InStr(title, "楽配くん") && !InStr(title, "参照用復元") && !InStr(title, "設定") && !InStr(title, "Cursor") && !InStr(title, ".md") {
                mainWin := title
                break 2
            }
        }
    }
    Sleep 500
}
if (mainWin = "") {
    WriteLog("失敗: 楽配くん10 が起動しませんでした")
    MsgBox "楽配くん10 が起動しませんでした。ショートカット名を確認してください。"
    ExitApp
}

; ウィンドウをアクティブにして前面に＆固定位置に移動
; ★親ウィンドウ「楽配くん10」を移動する（子ウィンドウ「メインメニュー」ではなく）
parentWin := "楽配くん10"
if !WinExist(parentWin) {
    parentWin := "楽配くん 10"  ; スペースありバージョンも試す
}
WriteLog("親ウィンドウを検出: " parentWin " (存在: " (WinExist(parentWin) ? "はい" : "いいえ") ")")

; 親ウィンドウが見つからない場合、mainWin を使用
if !WinExist(parentWin) {
    parentWin := mainWin
    WriteLog("親ウィンドウが見つからないため mainWin を使用: " parentWin)
}

WinActivate parentWin
Sleep 500

; ★移動前の位置を取得
beforeX := 0, beforeY := 0
try {
    WinGetPos &beforeX, &beforeY,,, parentWin
    WriteLog("移動前の位置: X=" beforeX ", Y=" beforeY)
}

; ★ウィンドウを画面左上（0, 0）に移動して位置を固定（座標ずれ防止）
WriteLog("ウィンドウを左上(0,0)に移動します...")
try {
    WinMove 0, 0,,, parentWin
    WriteLog("WinMove 実行完了")
} catch as e {
    WriteLog("WinMove 失敗: " e.Message)
}
Sleep 1000

; ★移動後の位置を取得
afterX := 0, afterY := 0
try {
    WinGetPos &afterX, &afterY,,, parentWin
    WriteLog("移動後の位置: X=" afterX ", Y=" afterY)
}

WinActivate parentWin  ; 念のため2回
WinWaitActive parentWin,, 10
Sleep 2000  ; ウィンドウが完全に描画されるまで待つ

; 楽配くんのウィンドウタイトルを確認
; ※Access アプリは MDI 構造のため、子ウィンドウ「メインメニュー」の存在で判定
WriteLog("楽配くんウィンドウを左上に配置しました")

; 「メインメニュー」子ウィンドウが存在するかチェック
isMainMenu := WinExist("メインメニュー")
if !isMainMenu {
    ; 他の画面（基本処理、特殊処理など）が開いているか確認
    otherScreen := ""
    for checkTitle in ["基本処理", "特殊処理", "集計処理", "宅配先情報", "データ出力", "マスター情報"] {
        if WinExist(checkTitle) {
            otherScreen := checkTitle
            break
        }
    }
    if (otherScreen != "") {
        WriteLog("スキップ: メインメニュー画面ではありません（" otherScreen "）")
        MsgBox("楽配くんがメインメニュー画面ではないため、復元をスキップしました。`n`n現在の画面: " otherScreen "`n`nメインメニュー画面に戻してから再実行してください。", "楽配くん 自動復元")
    } else {
        WriteLog("スキップ: メインメニューウィンドウが見つかりません")
        MsgBox("楽配くんのメインメニュー画面が見つかりません。`n`nメインメニュー画面を開いてから再実行してください。", "楽配くん 自動復元")
    }
    ExitApp
}
WriteLog("メインメニューを検出: " mainWin)

; 3) 「特殊処理」ボタンの座標（なければキャプチャ）
if (specialScreenX = 0 || specialScreenY = 0) {
    MsgBox("【初回設定 1/5】`n`n楽配くんは画面左上に配置されています。`nマウスを「特殊処理」ボタンの上に動かしてください。`n`n位置が決まったら Enter キーを押してください。", "座標キャプチャ")
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &specialScreenX, &specialScreenY
    SavePos("SpecialX", specialScreenX)
    SavePos("SpecialY", specialScreenY)
    WriteLog("特殊処理ボタン座標を保存: X=" specialScreenX ", Y=" specialScreenY)
}

WriteLog("特殊処理ボタンをクリック: X=" specialScreenX ", Y=" specialScreenY)

; 楽配くんを前面に出してからクリック
WinActivate parentWin
Sleep 500
WinWaitActive parentWin,, 3

; 確実にクリック（3回試行）
Loop 3 {
    ReliableClick(specialScreenX, specialScreenY, 1500)
    
    ; 特殊処理ウィンドウが開いたか確認
    if WinExist("特殊処理") {
        break
    }
    WriteLog("クリック試行 " A_Index " 回目: 特殊処理ウィンドウ未検出")
    Sleep 1000
}

; 4) 「特殊処理」ウィンドウを待つ
specialFound := false
Loop 60 {
    if WinExist("特殊処理") {
        specialFound := true
        WinActivate "特殊処理"
        break
    }
    Sleep 500
}
if !specialFound {
    WriteLog("失敗: 特殊処理画面が開きませんでした")
    MsgBox "特殊処理画面が開きませんでした。`n`nrakuhai-pos.ini を削除して再実行すると、座標を再設定できます。"
    ExitApp
}
WriteLog("特殊処理画面を開いた")
Sleep 1000

; 5) 「バックアップ／復元処理」ボタンの座標
if (backupScreenX = 0 || backupScreenY = 0) {
    MsgBox("【初回設定 2/5】`n`nマウスを「バックアップ／復元処理」ボタンの上に動かしてください。`n`n位置が決まったら Enter キーを押してください。", "座標キャプチャ")
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &backupScreenX, &backupScreenY
    SavePos("BackupX", backupScreenX)
    SavePos("BackupY", backupScreenY)
    WriteLog("バックアップ復元処理ボタン座標を保存: X=" backupScreenX ", Y=" backupScreenY)
}

WriteLog("バックアップ復元処理ボタンをクリック: X=" backupScreenX ", Y=" backupScreenY)
WinActivate "特殊処理"
Sleep 500
WinWaitActive "特殊処理",, 3
ReliableClick(backupScreenX, backupScreenY, 2000)

; 6) 「参照用データ復元」が出るまで待つ
WriteLog("参照用データ復元画面を待機中...")
refWinFound := false
refTitle := ""
Loop 120 {  ; 最大60秒待つ
    for _, title in ["参照用データ復元", "参照用", "データ復元", "バックアップ"] {
        if WinExist(title) {
            refTitle := title
            refWinFound := true
            break 2
        }
    }
    Sleep 500
}
if !refWinFound {
    WriteLog("失敗: 参照用データ復元画面が開きませんでした")
    MsgBox "参照用データ復元画面が開きませんでした。"
    ExitApp
}
WriteLog("参照用データ復元画面を開いた: " refTitle)

; 7) タブと一覧のクリック
winForClick := WinExist("バックアップ") ? "バックアップ" : refTitle
WinActivate winForClick
Sleep 500
WinWaitActive winForClick,, 3
Sleep 500

; タブの座標
if (tabScreenX = 0 || tabScreenY = 0) {
    MsgBox("【初回設定 3/5】`n`nマウスを「自動バックアップ一覧」タブの上に動かしてください。`n`n位置が決まったら Enter キーを押してください。", "座標キャプチャ")
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &tabScreenX, &tabScreenY
    SavePos("TabX", tabScreenX)
    SavePos("TabY", tabScreenY)
    WriteLog("自動バックアップ一覧タブ座標を保存: X=" tabScreenX ", Y=" tabScreenY)
}

; タブをクリック
WriteLog("自動バックアップ一覧タブをクリック: X=" tabScreenX ", Y=" tabScreenY)
WinActivate winForClick
Sleep 300
ReliableClick(tabScreenX, tabScreenY, 1000)

; 一覧の1行目の座標
if (listScreenX = 0 || listScreenY = 0) {
    MsgBox("【初回設定 4/5】`n`nマウスを一覧の「1行目」（一番上の行）の上に動かしてください。`n`n位置が決まったら Enter キーを押してください。", "座標キャプチャ")
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &listScreenX, &listScreenY
    SavePos("ListX", listScreenX)
    SavePos("ListY", listScreenY)
    WriteLog("一覧1行目座標を保存: X=" listScreenX ", Y=" listScreenY)
}

; 一覧の1行目をクリック
WriteLog("一覧の1行目をクリック: X=" listScreenX ", Y=" listScreenY)
WinActivate winForClick
Sleep 300
ReliableClick(listScreenX, listScreenY, 800)

; 8) 復元ボタンの座標
if (restoreScreenX = 0 || restoreScreenY = 0) {
    MsgBox("【初回設定 5/5】`n`nマウスを「復元」ボタンの上に動かしてください。`n`n位置が決まったら Enter キーを押してください。", "座標キャプチャ")
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &restoreScreenX, &restoreScreenY
    SavePos("RestoreX", restoreScreenX)
    SavePos("RestoreY", restoreScreenY)
    WriteLog("復元ボタン座標を保存: X=" restoreScreenX ", Y=" restoreScreenY)
}

WriteLog("復元ボタンをクリック: X=" restoreScreenX ", Y=" restoreScreenY)
WinActivate winForClick
Sleep 300
ReliableClick(restoreScreenX, restoreScreenY, 1000)

; 9) 確認ダイアログを待つ
WriteLog("確認ダイアログを待機中...")
confirmFound := false
Loop 40 {  ; 最大20秒待つ
    if WinExist("楽配くん", "復元") {
        confirmFound := true
        break
    }
    Sleep 500
}

if confirmFound {
    WinActivate "楽配くん", "復元"
    Sleep 500
    
    if (autoConfirm = 1) {
        Send "y"   ; 「はい(Y)」を押す
        WriteLog("復元処理を開始（最大6分待機）...")
        
        ; 復元完了ダイアログ「バックアップデータを復元しました」を待つ（最大6分）
        restoreComplete := false
        Loop 720 {  ; 最大360秒（6分）待つ
            if WinExist("楽配くん", "復元しました") {
                restoreComplete := true
                break
            }
            Sleep 500
        }
        
        if restoreComplete {
            ; 「OK」を押して完了ダイアログを閉じる
            WinActivate "楽配くん", "復元しました"
            Sleep 300
            Send "{Enter}"
            WriteLog("成功: 復元が完了しました")
            Sleep 1000
        } else {
            WriteLog("警告: 復元完了ダイアログが検出できませんでした（タイムアウト）")
        }
        
        ; すべてのウィンドウを閉じてデスクトップに戻す
        CloseAllRakuhaiWindows()
        WriteLog("すべてのウィンドウを閉じました")
        
        MsgBox("復元を自動で実行しました。`nウィンドウを閉じてデスクトップに戻しました。", "楽配くん 自動復元", "T5")
    } else {
        WriteLog("成功: 確認ダイアログまで到達（手動確認待ち）")
        MsgBox "確認ダイアログが表示されました。`n「はい」を手動で押して復元を完了してください。"
    }
} else {
    WriteLog("警告: 確認ダイアログが表示されませんでした")
    MsgBox "確認ダイアログが表示されませんでした。`n画面を確認してください。"
}

WriteLog("========== 復元処理終了 ==========")

; すべての楽配くん関連ウィンドウを閉じる関数
CloseAllRakuhaiWindows() {
    Sleep 2000
    
    titles := ["バックアップ", "参照用データ復元", "特殊処理", "メインメニュー", "楽配くん"]
    for _, title in titles {
        Loop 3 {  ; 各ウィンドウを3回試行
            if WinExist(title) {
                try {
                    WinClose title
                    Sleep 500
                }
            } else {
                break
            }
        }
    }
}
