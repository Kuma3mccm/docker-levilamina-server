#!/usr/bin/env sh

stty size cols 80

export HOME=/data
export WINEPREFIX=/data/.wine
export XDG_RUNTIME_DIR=/data/.tmp

# 日本語環境設定（文字化け対策）
export LANG=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja
export LC_ALL=ja_JP.UTF-8
export TERM=xterm-256color

VERSION="${VERSION:-LATEST}"

echo "=== LeviLamina サーバー起動 (日本語対応版) ==="
echo "ロケール: $LANG"
echo "日時: $(date)"
echo "バージョン: ${VERSION}"
echo "EULA: ${EULA:-未設定}"

if [ "$EULA" != "TRUE" ]
then
    echo "エラー: Minecraft EULA に同意する必要があります"
    echo "環境変数 EULA を TRUE に設定してください"
    exit 1
fi

if [ ! -d "/data/.tmp" ]
then
    mkdir -p /data/.tmp
fi

if [ ! -d "/data/.wine" ]
then
    echo "Wine 環境を初期化中..."
    xvfb-run -a wineboot --init
    echo "Wine 初期化完了"
    
    echo ".NET 10 と Visual C++ をインストール中..."
    xvfb-run -a winetricks -q dotnet10
    xvfb-run -a winetricks -q vcrun2022
    echo "ランタイムインストール完了"
fi

export WINEDEBUG="${WINEDEBUG:--all}"

if [ ! -f "bedrock_server_mod.exe" ]; then
    echo "LeviLamina をインストール中..."
    
    if [ -n "$GITHUB_MIRROR_URL" ]; then
        lip config set github_proxy "$GITHUB_MIRROR_URL"
        echo "GitHub ミラー設定: $GITHUB_MIRROR_URL"
    fi
    
    if [ -n "$GO_MODULE_PROXY_URL" ]; then
        lip config set go_module_proxy "$GO_MODULE_PROXY_URL"
        echo "Go モジュールプロキシ設定: $GO_MODULE_PROXY_URL"
    fi
    
    if [ "$VERSION" = "LATEST" ]; then
        lip install github.com/LiteLDev/LeviLamina
    else
        lip install github.com/LiteLDev/LeviLamina@"$VERSION"
    fi
    
    if [ -n "$PACKAGES" ]; then
        echo "追加パッケージをインストール中: $PACKAGES"
        lip install $PACKAGES
    fi
    
    echo "LeviLamina インストール完了"
fi

echo "=== LeviLamina サーバ起動中 ==="
echo "サーバディレクトリ: $(pwd)"

# 起動（エラー出力も日本語で表示）
(cat | wine bedrock_server_mod.exe) 2>&1
