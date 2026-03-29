# LeviStoneフリーズ問題の追加調査 (標準入力のブロック解除)

エラーログが出ずに進行が止まる（ハングする）現象について、最後に残る大きな可能性として「サーバープロセスへの標準入力（(cat | ...) パイプ）」が、組み込みPythonの I/O 初期化処理等と干渉してデッドロックを起こしていることが疑われます。

## 修正内容

`wine/entrypoint.sh` の最末尾にある起動コマンドを変更します。
従来はPterodactylからのコンソール入力を維持するためか `(cat | wine bedrock_server_mod.exe) 2>&1` とされていましたが、これを直接 `wine bedrock_server_mod.exe` を割り当てる形（または入力を遮断する形）に変更し、サーバー本体が起動手順を進められるか検証します。

```diff
- (cat | wine bedrock_server_mod.exe) 2>&1
+ wine bedrock_server_mod.exe
```

これにより、tty起因のハングアップであれば解消されるはずです。もしこれで起動が成功した場合、Pterodactylコンソールからのコマンド（`stop` など）が受け付けられるかどうかの確認を後ほど行う必要があります。
