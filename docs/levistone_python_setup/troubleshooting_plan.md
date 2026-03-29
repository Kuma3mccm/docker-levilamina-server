# LeviStone フリーズ問題のトラブルシューティング

LeviStone (EndstoneRuntime) がロードされた直後にサーバーがフリーズ（またはクラッシュして見えないエラーダイアログによりハング）する現象が発生しています。

## 考えられる原因と対策

1. **Wineのエラーダイアログによるブロッキング**
   LeviStoneが中でエラーを起こしているが、Wineがエラーダイアログ（GUI）を出そうとしてコンソール環境で止まっている可能性があります。
   -> `WINEDEBUG=-all` などの設定や、`HKCU\Software\Wine\WineDbg` の `ShowCrashDialog` をオフにする処理を追加します。
2. **Pythonの依存関係の未解決**
   Pythonの `python311._pth` に `plugins/EndstoneRuntime` などが含まれていない、または Embeddable パッケージによる制限でライブラリ読み込みに失敗している可能性があります。
   -> レジストリで `PYTHONPATH` に `plugins/EndstoneRuntime` のパスを追加するか、`PYTHONHOME` を明示的に指定します。
3. **標準入力パイプ（`cat`）との干渉**
   Python側がターミナル入力をブロックしている可能性があります。

## 実施する変更 (entrypoint.sh)

```sh
# Wineでのクラッシュダイアログを無効化
wine reg add "HKCU\\Software\\Wine\\WineDbg" /v ShowCrashDialog /t REG_DWORD /d 0 /f || true

# PYTHONPATH と PYTHONHOME の追加
wine reg add "HKCU\\Environment" /v PYTHONPATH /t REG_SZ /d "C:\\Python\\Lib;C:\\Python\\site-packages;Z:\\home\\container\\plugins\\EndstoneRuntime" /f || true
```

また、Pythonが `site-packages` や標準モジュールを正しく読み込めているかテストするために、インストールした `plugins/EndstoneRuntime` のパスをWindows形式で正しく渡す必要があります。

これらの設定を `entrypoint.sh` に追加し、現象が改善されるか（あるいは明確なエラーログが出力されるように）改修します。
