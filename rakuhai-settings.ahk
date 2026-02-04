#Requires AutoHotkey v2.0
#SingleInstance Force

configPath := A_ScriptDir "\rakuhai-config.ini"
scriptPath := A_ScriptDir "\rakuhai-auto-restore.ahk"

; 設定を読み込む
autoConfirm := 0
scheduleEnabled := 0
scheduleTime := "19:00"
ifPCOff := "RunAtLogon"
ifInUse := "Skip"

if FileExist(configPath) {
    try {
        autoConfirm := Integer(IniRead(configPath, "Settings", "AutoConfirm", "0"))
        scheduleEnabled := Integer(IniRead(configPath, "Settings", "ScheduleEnabled", "0"))
        scheduleTime := IniRead(configPath, "Settings", "ScheduleTime", "19:00")
        ifPCOff := IniRead(configPath, "Settings", "IfPCOff", "RunAtLogon")
        ifInUse := IniRead(configPath, "Settings", "IfInUse", "Skip")
    }
}

; 時刻を時・分に分割
timeParts := StrSplit(scheduleTime, ":")
schedHour := timeParts.Length >= 1 ? timeParts[1] : "19"
schedMin := timeParts.Length >= 2 ? timeParts[2] : "00"

; 分リストを作成（00〜59）
minList := []
Loop 60
    minList.Push(Format("{:02d}分", A_Index - 1))

; GUI作成
myGui := Gui(, "楽配くん 参照用復元 - 設定")
myGui.BackColor := "F0F0F0"
myGui.SetFont("s10", "Meiryo UI")

myGui.Add("Text", "xm ym w450", "楽配くんの「参照用データ復元」を自動で行う設定です。")
myGui.Add("Text", "xm y+2 w450 c888888", "変更後は「保存して閉じる」を押してください。")

myGui.Add("Text", "xm y+15 w450 h2 0x10")

; 確認ダイアログ
myGui.Add("Text", "xm y+10", "■ 確認ダイアログ")
chkAuto := myGui.Add("CheckBox", "xm y+6 vAutoConfirm", "「復元してよろしいですか？」を自動で「はい」にする")
chkAuto.Value := autoConfirm
myGui.Add("Text", "xm y+2 c888888", "オフの場合は、毎回手動で「はい」を押します。")

; 実行方法
myGui.Add("Text", "xm y+15", "■ 実行方法")
ddMode := myGui.Add("DDL", "xm y+6 w400 vScheduleMode Choose" (scheduleEnabled ? 2 : 1), ["手動のみ（予約なし）", "予約時刻あり（毎日自動実行）"])

; 実行時刻
myGui.Add("Text", "xm y+10", "実行時刻（予約ありの場合）")
hourList := []
Loop 24
    hourList.Push(Format("{:d}時", A_Index - 1))
ddHour := myGui.Add("DDL", "xm y+4 w60 vHour Choose" (Integer(schedHour) + 1), hourList)
ddMin := myGui.Add("DDL", "x+5 w70 vMinute Choose" (Integer(schedMin) + 1), minList)

; PCオフ時
myGui.Add("Text", "xm y+12", "PCの電源が切れていたとき（予約時刻を逃した場合）")
ddPCOff := myGui.Add("DDL", "xm y+4 w400 vIfPCOff Choose" ((ifPCOff = "Skip") ? 2 : 1), ["次回ログオン後に実行する", "その日は実行しない"])

; 作業中
myGui.Add("Text", "xm y+10", "予約時刻に誰かが楽配くんを使っているとき")
ddInUse := myGui.Add("DDL", "xm y+4 w400 vIfInUse Choose" ((ifInUse = "Run") ? 2 : 1), ["スキップする（おすすめ）", "そのまま実行する"])

myGui.Add("Text", "xm y+15 w450 h2 0x10")

; ボタン
btnSave := myGui.Add("Button", "xm y+10 w130", "保存して閉じる")
btnSave.OnEvent("Click", SaveSettings)

btnRun := myGui.Add("Button", "x+10 w130", "今すぐ復元実行")
btnRun.OnEvent("Click", RunRestore)

btnTask := myGui.Add("Button", "x+10 w130", "予約をタスクに登録")
btnTask.OnEvent("Click", RegisterTask)

btnShortcut := myGui.Add("Button", "xm y+8 w200", "デスクトップにショートカット作成")
btnShortcut.OnEvent("Click", CreateShortcut)

btnLog := myGui.Add("Button", "x+10 w100", "ログを見る")
btnLog.OnEvent("Click", ViewLog)

myGui.Show("AutoSize")
return

; 保存
SaveSettings(*) {
    global myGui, configPath, ddMode, ddHour, ddMin, ddPCOff, ddInUse, chkAuto
    
    ; DDLのValueプロパティでインデックスを取得
    hourIdx := ddHour.Value
    minIdx := ddMin.Value
    hourStr := Format("{:d}", hourIdx - 1)
    minStr := Format("{:02d}", minIdx - 1)
    timeStr := hourStr ":" minStr
    
    pcOffVal := (ddPCOff.Value = 2) ? "Skip" : "RunAtLogon"
    inUseVal := (ddInUse.Value = 2) ? "Run" : "Skip"
    schedOn := (ddMode.Value = 2) ? "1" : "0"
    autoVal := chkAuto.Value ? "1" : "0"
    
    IniWrite autoVal, configPath, "Settings", "AutoConfirm"
    IniWrite schedOn, configPath, "Settings", "ScheduleEnabled"
    IniWrite timeStr, configPath, "Settings", "ScheduleTime"
    IniWrite pcOffVal, configPath, "Settings", "IfPCOff"
    IniWrite inUseVal, configPath, "Settings", "IfInUse"
    
    MsgBox("設定を保存しました。", "楽配くん 設定", "T2")
    ExitApp
}

; 今すぐ実行
RunRestore(*) {
    global scriptPath
    if FileExist(scriptPath)
        Run scriptPath
    else
        MsgBox("復元スクリプトが見つかりません。", "エラー")
}

; タスク登録
RegisterTask(*) {
    global myGui, scriptPath, ddMode, ddHour, ddMin
    
    if (ddMode.Value != 2) {
        MsgBox("「予約時刻あり」を選んでから登録してください。", "楽配くん 設定")
        return
    }
    
    hourStr := Format("{:d}", ddHour.Value - 1)
    minStr := Format("{:02d}", ddMin.Value - 1)
    ahkExe := A_AhkPath
    
    ; schtasks コマンド
    taskCmd := 'schtasks /create /tn "楽配くん参照用復元" /tr "\"' ahkExe '\" \"' scriptPath '\"" /sc daily /st ' hourStr ':' minStr ' /f'
    exitCode := RunWait(taskCmd,, "Hide")
    
    if (exitCode = 0)
        MsgBox("予約タスクを登録しました。`n毎日 " hourStr ":" minStr " に実行されます。", "楽配くん 設定")
    else
        MsgBox("タスク登録に失敗しました。`n管理者として実行してから再度お試しください。", "楽配くん 設定")
}

; ログを見る
ViewLog(*) {
    logFile := A_ScriptDir "\rakuhai-restore-log.txt"
    if FileExist(logFile)
        Run "notepad.exe `"" logFile "`""
    else
        MsgBox("ログファイルがまだありません。`n復元を実行するとログが作成されます。", "楽配くん 設定")
}

; ショートカット作成
CreateShortcut(*) {
    try {
        sh := ComObject("WScript.Shell")
        lnk := sh.CreateShortcut(A_Desktop "\楽配くん 設定.lnk")
        lnk.TargetPath := A_AhkPath
        lnk.Arguments := '"' A_ScriptFullPath '"'
        lnk.WorkingDirectory := A_ScriptDir
        lnk.Description := "楽配くん 参照用復元の設定"
        lnk.Save()
        MsgBox("デスクトップにショートカットを作成しました。", "楽配くん 設定", "T2")
    } catch as e {
        MsgBox("ショートカット作成に失敗: " e.Message, "エラー")
    }
}
