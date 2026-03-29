# 修正内容の確認 (Walkthrough): LeviStone用Python環境の導入

Wine環境上でLeviStone（Python製ツール）を動作させるための基盤として、Windows版Python 3.11の導入を行いました。

## 行った変更内容

### 1. `wine/Dockerfile`の修正

- Pythonパッケージの展開のために `unzip` をインストールパッケージリストに追加しました。
- Windows向けPython 3.11 (Embeddable)パッケージをダウンロードし、`/usr/local/wine-python` に展開しました。
- `get-pip.py` をダウンロードし、`python311._pth` の `import site` を有効化して、サードパーティ製ライブラリのインストールを可能にしました。

```diff
-    locales ca-certificates curl wget xz-utils libicu-dev \
+    locales ca-certificates curl wget xz-utils libicu-dev unzip \

+RUN mkdir -p /usr/local/wine-python \
+    && curl -L https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip -o /tmp/python.zip \
+    && unzip /tmp/python.zip -d /usr/local/wine-python \
+    && rm /tmp/python.zip \
+    && cd /usr/local/wine-python \
+    && curl -L https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
+    && sed -i 's/#import site/import site/' python311._pth
```

### 2. `wine/entrypoint.sh` の修正

- Wine環境初期化後（`drive_c`作成後）に、コンテナ内に用意したPythonのファイルを `$WINEPREFIX/drive_c/Python` にコピーする処理を追加しました。
- コピー後、`wine cmd /c "C:\\Python\\python.exe C:\\Python\\get-pip.py"` を実行してpipをインストールするようにしました。
- `wine reg add` コマンドでWine環境のレジストリを操作し、`C:\Python` および `C:\Python\Scripts` を `PATH` 環境変数に追加しました。これにより、コマンドラインから直接 `python` または `pip` を呼び出せるようになります。

```diff
+if [ ! -d "$WINEPREFIX/drive_c/Python" ]; then
+    echo "[2.5] Python (Windows) 環境を構成中..."
+    cp -r /usr/local/wine-python "$WINEPREFIX/drive_c/Python"
+    # pipのインストールを実行
+    wine cmd /c "C:\\Python\\python.exe C:\\Python\\get-pip.py" || true
+    # レジストリにPATHを追加
+    wine reg add "HKCU\\Environment" /v PATH /t REG_SZ /d "C:\\Python;C:\\Python\\Scripts;%PATH%" /f || true
+fi
```

## 今後の作業 (必要に応じて)

今回作成した環境で実際にLeviStoneを動作させるには、`bedrock_server_mod.exe`の起動前（または起動コマンド部分）に、LeviStoneのリポジトリのクローンや `pip install -r requirements.txt` 、および `python main.py` の実行といった手順を `entrypoint.sh` に追記するか、手動でセットアップする必要があります。
今回の変更では、その基盤となるPython環境の導入までを完了しています。
