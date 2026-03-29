# 実装計画: LeviStoneのためのPython(Wine)導入

Docker環境内のWine上でLeviStoneを動作させるために、Windows版のPythonをインストールする仕組みを構築します。

## 修正内容

### 1. `wine/Dockerfile` の修正

Dockerfile内で以下の処理を追加します。

- 必要なパッケージとして `unzip` を追加します。
- Windows向けのPython（Embeddableパッケージ、ここでは安定版の3.11系を使用します）をダウンロードし、`/usr/local/wine-python` に展開します。
- Pipが使用できるように、`get-pip.py` をダウンロードし、`python311._pth` の `import site` 行を有効化して、サードパーティ製ライブラリのインストールを可能にします。

#### [MODIFY] wine/Dockerfile

```dockerfile
# 変更前
RUN apt-get update && apt-get install -y \
    locales ca-certificates curl wget xz-utils libicu-dev \
# 変更後
RUN apt-get update && apt-get install -y \
    locales ca-certificates curl wget xz-utils libicu-dev unzip \

# 新規追加
# Windows向けPython 3.11 (Embeddable) を /usr/local/wine-python に用意
RUN mkdir -p /usr/local/wine-python \
    && curl -L https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip -o /tmp/python.zip \
    && unzip /tmp/python.zip -d /usr/local/wine-python \
    && rm /tmp/python.zip \
    && cd /usr/local/wine-python \
    && curl -L https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && sed -i 's/#import site/import site/' python311._pth
```

### 2. `wine/entrypoint.sh` の修正

Wine環境 (`$WINEPREFIX`) はコンテナ起動時に `/home/container/.wine` として作成・永続化されます。そのため、コンテナ起動時にPythonをWineの `drive_c` 内に配置し、PATHを通すなどの初期化処理を追加します。

#### [MODIFY] wine/entrypoint.sh

```sh
# Wine 初期化完了後に以下の処理を挿入
if [ ! -d "$WINEPREFIX/drive_c/Python" ]; then
    echo "[2.5] Python (Windows) 環境を構成中..."
    cp -r /usr/local/wine-python "$WINEPREFIX/drive_c/Python"
    # pipのインストールを実行
    wine cmd /c "C:\\Python\\python.exe C:\\Python\\get-pip.py" || true
    # レジストリにPATHを追加
    wine reg add "HKCU\\Environment" /v PATH /t REG_SZ /d "C:\\Python;C:\\Python\\Scripts;%PATH%" /f || true
fi
```

## ユーザーへの確認事項

> [!NOTE]  
> 以上の計画でよろしいでしょうか？Pythonのバージョンに指定がある場合（例: 3.10や3.12など）はお知らせください。基本的にはLeviStoneが要求する仕様に合致するよう 3.11 を選択しています。
