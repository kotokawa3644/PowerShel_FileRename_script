# PowerShel_FileRename_script
保存されるファイル名称を、撮影日付＋連番＋時刻.拡張子 自動変換します。

対象拡張子は、現在、$extPattern = '^(jpg|jpeg|png|mov|mp4|webm|jxr|arw|tif|dng|m4v)$'

対象ホルダーは、$watchPath = "Z:\Screenshot" を書き換え下さい。

$exiftool  = "C:\Tools\exiftool.exe" が必要です。https://exiftool.org/

変換済み（yyyMMdd_***_HHmm.***）は、対象となりません。

変換済み同名ファイル（例:ドキュメント.png）保存、何度も可能です。

動画など、コピー時間かかる時、保存完了まで変換待ちます。

自動起動は、BATファイル作成が便利です。

連番は、拡張子毎です。

日時は、作成日時です。
