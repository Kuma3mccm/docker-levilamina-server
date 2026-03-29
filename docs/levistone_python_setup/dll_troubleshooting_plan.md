# LeviStoneトラブルシューティング (4): 依存DLLのパス問題

`cat`パイプを外しても解決しなかった（即時エラー終了した）ことから、コンソールの問題ではなく、LeviStone (EndstoneRuntime) がPython ( `python311.dll` ) を初期化する際に、パスの問題でDLLやリソースのロードに失敗し、例外でクラッシュ（`Exit code: 3`）している可能性が極めて高くなりました。

## 原因の仮説

Windows環境では、拡張機能（DLL）が別のDLL（python311.dll等）をロードする際、優先的に「実行ファイル(`bedrock_server_mod.exe`)と同じディレクトリ」を検索します。
PATH環境変数を設定していても、プロセス空間の変化やWineの特性により、`C:\Python` 配下に配置されたDLL等が正しくロードされず、Fatal Errorとして例外終了していると考えられます。

## 修正内容

問題を解消し確実な動作を確保するため、**Windows向けPython（Embeddable等）の中身をすべて `bedrock_server_mod.exe` と同じディレクトリ（`/home/container`）にコピーする** アプローチに切り替えます。
これにより、LeviLaminaからホストされるEndstoneRuntimeが `python311.dll` に容易にアクセスでき、レジストリやPATHに依存せず動作する可能性が高まります。

1. `wine/entrypoint.sh` を修正し、コンテナ起動時に `/usr/local/wine-python/` の内容を `/home/container/` 直下にコピーします。
2. 標準入力パイプ `(cat | ...)` は元に戻します。
3. `python311._pth` ファイルに `plugins/EndstoneRuntime` へのパス（相対パス）を書き込む処理を追加します。
