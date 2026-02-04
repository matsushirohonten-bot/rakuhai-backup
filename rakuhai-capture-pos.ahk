#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "Mouse", "Window"

posFile := A_ScriptDir "\rakuhai-pos.txt"
FileDelete posFile  ; 古い記録を削除（無視してOK）

MsgBox "
(
座標キャプチャを開始します。

操作方法：
1. 楽配くん10を起動し、対象の画面を表示してください。
2. マウスをそれぞれの場所に合わせて、次のキーを押します。
   F1: メインメニューの「特殊処理」ボタン
   F2: 「バックアップ／復元処理」ボタン
   F3: 「自動バックアップ一覧」タブ
   F4: 一覧の「1行目」（自動バックアップ一覧タブを開いた状態で、リストの一番上の行の中央）
3. 全部取り終わったら Esc キーで終了します。
)"

F1::
{
    MouseGetPos &x, &y
    FileAppend "special " x " " y "`n", posFile
    TrayTip "特殊処理ボタンの座標を記録しました: " x ", " y
}

F2::
{
    MouseGetPos &x, &y
    FileAppend "backup " x " " y "`n", posFile
    TrayTip "バックアップ／復元処理ボタンの座標を記録しました: " x ", " y
}

F3::
{
    MouseGetPos &x, &y
    FileAppend "auto_tab " x " " y "`n", posFile
    TrayTip "自動バックアップ一覧タブの座標を記録しました: " x ", " y
}

F4::
{
    MouseGetPos &x, &y
    FileAppend "list_first " x " " y "`n", posFile
    TrayTip "一覧の1行目の座標を記録しました: " x ", " y
}

Esc::ExitApp

