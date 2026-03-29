# LeviStoneトラブルシューティング (4): 依存DLLパス問題の修正

前回の検証で、問題は「標準入力パイプ（TTY）」ではなく「Levistone(EndstoneRuntime) 初期化時の Fatal Error (例外終了)」であることが判明しました。
Windows版Pythonのファイル群を別のディレクトリ(`C:\Python`)に置き、PATH環境変数で参照させていたことで、LevilaminaプラグインからDLLが正しく見つけられず、即死（Exit Code 3）していたと考えられます。

## 実施した対策

`wine/entrypoint.sh` を修正し、コンテナ起動時のPython環境構築方法を変更しました。

1. **カレントディレクトリへの展開**
   Python Embeddableパッケージのファイル群（`python311.dll` 等）を、サーバー本体（`bedrock_server_mod.exe`）と同じディレクトリ（`/home/container/`）に直接コピーするようにしました。
   これにより、WindowsのDLL検索ルールに従って確実にPythonのランタイムがロードされるようになります。
2. **`._pth` ファイルの相対パス修正**
   `python311._pth` に `plugins\EndstoneRuntime` への相対パスを直接追記し、Levistoneの依存ライブラリが適切に解決されるように変更しました。
3. **標準入力ストリームの復元**
   前回外した標準入力の維持用コマンド `(cat | wine bedrock_server_mod.exe) 2>&1` を元に戻し、サーバーが正常に起動・待機できるようにしました。

## 確認のお願い

上記の修正が適用された状態でもう一度コンテナの再起動（サーバーの起動）をお試しください。
依存関係が正しく解決されていれば、`EndstoneRuntimeがロードされました` の後にBedrock Dedicated Server本来の起動ログが続くようになり、正常にサーバーが開始されます。
