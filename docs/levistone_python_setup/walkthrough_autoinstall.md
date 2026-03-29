# 実装と確認 (Walkthrough): LeviStone自動インストール

## 行った変更内容

### `wine/entrypoint.sh` の修正

サーバー起動時にLeviStoneがインストールされているか確認し、存在しない場合は自動でインストールする処理を組み込みました。

```diff
 echo "[4] 自前 LeviLamina の存在確認..."
 ls -la bedrock_server_mod.exe || { echo "[4] エラー: bedrock_server_mod.exe がありません"; exit 1; }

+echo "[4.5] LeviStone の自動インストール確認..."
+if [ ! -d "plugins/EndstoneRuntime/levistone" ]; then
+    echo "[4.5] LeviStone を自動インストールしています..."
+    mkdir -p plugins/EndstoneRuntime
+    wine cmd /c "C:\\Python\\python.exe -m pip install levistone --target plugins/EndstoneRuntime" || echo "[4.5] 警告: pip install に失敗した可能性があります"
+else
+    echo "[4.5] LeviStone はインストール済みです"
+fi
+
 echo "[5] Wine バージョン確認..."
 wine --version || echo "[5] wine --version 取得失敗"
```

## 動作について

Pterodactyl内でコンテナが起動した際、`plugins/EndstoneRuntime` フォルダの構築と `pip install levistone` コマンドが実行され、初回のみプラグインファイルが自動でダウンロード、配置されます。次回以降は `plugins/EndstoneRuntime/levistone` ディレクトリが存在するため、インストール処理はスキップされます。
