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

; ========== 座標設定 ==========
rakuhaiShortcut := A_Desktop "\楽配くん参照用.lnk"
posFile := A_ScriptDir "\rakuhai-pos.txt"

; デフォルト座標（ウィンドウ相対）
x_special := 674
y_special := 240
x_backup := 452
y_backup := 161
x_auto_tab := 349
y_auto_tab := 298
x_list_first := 250
y_list_first := 345

; rakuhai-pos.txt から座標を読み込む
tabScreenX := 0
tabScreenY := 0
listScreenX := 0
listScreenY := 0

if FileExist(posFile) {
    loop read, posFile {
        line := Trim(A_LoopReadLine)
        if (SubStr(line, 1, 9) = "auto_tab ") {
            parts := StrSplit(line, " ")
            if (parts.Length >= 3) {
                x_auto_tab := Integer(parts[2])
                y_auto_tab := Integer(parts[3])
            }
        } else if (SubStr(line, 1, 11) = "list_first ") {
            parts := StrSplit(line, " ")
            if (parts.Length >= 3) {
                x_list_first := Integer(parts[2])
                y_list_first := Integer(parts[3])
            }
        } else if (SubStr(line, 1, 16) = "auto_tab_screen ") {
            parts := StrSplit(line, " ")
            if (parts.Length >= 3) {
                tabScreenX := Integer(parts[2])
                tabScreenY := Integer(parts[3])
            }
        } else if (SubStr(line, 1, 17) = "list_first_screen") {
            parts := StrSplit(line, " ")
            if (parts.Length >= 3) {
                listScreenX := Integer(parts[2])
                listScreenY := Integer(parts[3])
            }
        }
    }
}

; ========== メイン処理開始 ==========
WriteLog("========== 復元処理を開始 ==========")

; 1) 楽配くんが既に起動しているかチェック（設定画面は除外）
alreadyRunning := false
if WinExist("メインメニュー") {
    alreadyRunning := true
} else {
    ; 「楽配くん」を含むが「参照用復元」「設定」を含まないウィンドウを探す
    for hwnd in WinGetList() {
        try {
            title := WinGetTitle(hwnd)
            if InStr(title, "楽配くん") && !InStr(title, "参照用復元") && !InStr(title, "設定") {
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

; 2) メインメニューが開くまで待つ（設定画面は除外）
WriteLog("メインメニューを待機中...")
mainWin := ""
Loop 120 {  ; 最大60秒待つ
    if WinExist("メインメニュー") {
        mainWin := "メインメニュー"
        break
    }
    ; 「楽配くん」を含むが「参照用復元」「設定」を含まないウィンドウを探す
    for hwnd in WinGetList() {
        try {
            title := WinGetTitle(hwnd)
            if InStr(title, "楽配くん") && !InStr(title, "参照用復元") && !InStr(title, "設定") {
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

; ウィンドウをアクティブにして前面に
WinActivate mainWin
Sleep 1000
WinActivate mainWin  ; 念のため2回
WinWaitActive mainWin,, 10
Sleep 2000  ; ウィンドウが完全に描画されるまで待つ

; 楽配くんのウィンドウタイトルを確認
rakuhaiTitle := ""
try {
    rakuhaiTitle := WinGetTitle(mainWin)
}
WriteLog("楽配くんウィンドウ: " rakuhaiTitle)

; 「メインメニュー」または「楽配くん10」画面の場合のみ続行（それ以外はすべてスキップ）
isMainMenu := InStr(rakuhaiTitle, "メインメニュー") || (rakuhaiTitle = "楽配くん10") || (rakuhaiTitle = "楽配くん 10")
if !isMainMenu {
    WriteLog("スキップ: メインメニュー画面ではありません（" rakuhaiTitle "）")
    MsgBox("楽配くんがメインメニュー画面ではないため、復元をスキップしました。`n`n現在の画面: " rakuhaiTitle "`n`nメインメニュー画面に戻してから再実行してください。", "楽配くん 自動復元")
    ExitApp
}

WriteLog("メインメニューを検出: " mainWin)

; 3) 「特殊処理」ボタンのスクリーン座標を取得（初回は手動で指定）
specialScreenX := 0
specialScreenY := 0
if FileExist(posFile) {
    loop read, posFile {
        line := Trim(A_LoopReadLine)
        if (SubStr(line, 1, 15) = "special_screen ") {
            parts := StrSplit(line, " ")
            if (parts.Length >= 3) {
                specialScreenX := Integer(parts[2])
                specialScreenY := Integer(parts[3])
            }
        }
    }
}

; 座標が保存されていなければ手動で指定
if (specialScreenX = 0) {
    MsgBox("【初回設定】`n`nマウスを「特殊処理」ボタンの上に動かしてください。`n`n位置が決まったら Enter キーを押してください。", "座標キャプチャ")
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &specialScreenX, &specialScreenY
    FileAppend "special_screen " specialScreenX " " specialScreenY "`n", posFile
    WriteLog("特殊処理ボタン座標を保存: X=" specialScreenX ", Y=" specialScreenY)
}

WriteLog("特殊処理ボタンをクリック: X=" specialScreenX ", Y=" specialScreenY)

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
    MsgBox "特殊処理画面が開きませんでした。`n`nrakuhai-pos.txt を削除して再実行すると、座標を再設定できます。"
    ExitApp
}
WriteLog("特殊処理画面を開いた")
Sleep 1000

; 5) 「バックアップ／復元処理」ボタンのスクリーン座標を取得
backupScreenX := 0
backupScreenY := 0
if FileExist(posFile) {
    loop read, posFile {
        line := Trim(A_LoopReadLine)
        if (SubStr(line, 1, 14) = "backup_screen ") {
            parts := StrSplit(line, " ")
            if (parts.Length >= 3) {
                backupScreenX := Integer(parts[2])
                backupScreenY := Integer(parts[3])
            }
        }
    }
}

; 座標が保存されていなければ手動で指定
if (backupScreenX = 0) {
    MsgBox("【初回設定】`n`nマウスを「バックアップ／復元処理」ボタンの上に動かしてください。`n`n位置が決まったら Enter キーを押してください。", "座標キャプチャ")
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &backupScreenX, &backupScreenY
    FileAppend "backup_screen " backupScreenX " " backupScreenY "`n", posFile
    WriteLog("バックアップ復元処理ボタン座標を保存: X=" backupScreenX ", Y=" backupScreenY)
}

WriteLog("バックアップ復元処理ボタンをクリック: X=" backupScreenX ", Y=" backupScreenY)
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
Sleep 1500

; タブの画面座標がまだ保存されていなければ手動で指定
if (tabScreenX = 0) {
    MsgBox "マウスを「自動バックアップ一覧」タブの上に手動で動かしてください。`n`n位置が決まったら Enter キーを押してください。"
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &tabScreenX, &tabScreenY
    FileAppend "auto_tab_screen " tabScreenX " " tabScreenY "`n", posFile
    WriteLog("自動バックアップ一覧タブ座標を保存: X=" tabScreenX ", Y=" tabScreenY)
}

; タブをクリック
WriteLog("自動バックアップ一覧タブをクリック: X=" tabScreenX ", Y=" tabScreenY)
ReliableClick(tabScreenX, tabScreenY, 1000)

; 一覧の1行目の画面座標がまだ保存されていなければ手動で指定
if (listScreenX = 0) {
    MsgBox "マウスを一覧の「1行目」（一番上の行）の上に手動で動かしてください。`n`n位置が決まったら Enter キーを押してください。"
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &listScreenX, &listScreenY
    FileAppend "list_first_screen " listScreenX " " listScreenY "`n", posFile
    WriteLog("一覧1行目座標を保存: X=" listScreenX ", Y=" listScreenY)
}

; 一覧の1行目をクリック
WriteLog("一覧の1行目をクリック: X=" listScreenX ", Y=" listScreenY)
ReliableClick(listScreenX, listScreenY, 800)

; 8) 復元ボタンのスクリーン座標を取得
restoreScreenX := 0
restoreScreenY := 0
if FileExist(posFile) {
    loop read, posFile {
        line := Trim(A_LoopReadLine)
        if (SubStr(line, 1, 15) = "restore_screen ") {
            parts := StrSplit(line, " ")
            if (parts.Length >= 3) {
                restoreScreenX := Integer(parts[2])
                restoreScreenY := Integer(parts[3])
            }
        }
    }
}

; 座標が保存されていなければ手動で指定
if (restoreScreenX = 0) {
    MsgBox("【初回設定】`n`nマウスを「復元」ボタンの上に動かしてください。`n`n位置が決まったら Enter キーを押してください。", "座標キャプチャ")
    KeyWait "Enter", "D"
    Sleep 100
    MouseGetPos &restoreScreenX, &restoreScreenY
    FileAppend "restore_screen " restoreScreenX " " restoreScreenY "`n", posFile
    WriteLog("復元ボタン座標を保存: X=" restoreScreenX ", Y=" restoreScreenY)
}

WriteLog("復元ボタンをクリック: X=" restoreScreenX ", Y=" restoreScreenY)
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
