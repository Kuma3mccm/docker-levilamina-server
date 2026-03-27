#!/usr/bin/env sh

stty size cols 80

# Pterodactyl のデフォルトワークディレクトリに合わせる
cd /home/container

export HOME=/home/container
export WINEPREFIX=/home/container/.wine
export XDG_RUNTIME_DIR=/home/container/.tmp

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

if [ "$EULA" != "TRUE" ]; then
    echo "エラー: EULA=TRUE が必要です"
    exit 1
fi

# ディレクトリ作成（/home/container は Pterodactyl では書き込み可）
mkdir -p "$XDG_RUNTIME_DIR"

if [ ! -d "$WINEPREFIX" ]; then
    echo "Wine 環境を初期化中..."
    xvfb-run -a wineboot --init
    echo "Wine 初期化完了"

    echo ".NET 10 と Visual C++ をインストール中..."
    xvfb-run -a winetricks -q dotnet10
    xvfb-run -a winetricks -q vcrun2022
    echo "ランタイムインストール完了"
fi

# ここから先は /home/container を基準に LeviLamina を入れる
if [ ! -f "bedrock_server_mod.exe" ]; then
    echo "LeviLamina をインストール中..."

    if [ -n "$GITHUB_MIRROR_URL" ]; then
        lip config set github_proxy "$GITHUB_MIRROR_URL"
    fi
    if [ -n "$GO_MODULE_PROXY_URL" ]; then
        lip config set go_module_proxy "$GO_MODULE_PROXY_URL"
    fi

    if [ "$VERSION" = "LATEST" ]; then
        lip install github.com/LiteLDev/LeviLamina
    else
        lip install github.com/LiteLDev/LeviLamina@"$VERSION"
    fi

    if [ -n "$PACKAGES" ]; then
        lip install $PACKAGES
    fi
    echo "LeviLamina インストール完了"
fi

echo "=== LeviLamina サーバ起動中 ==="
echo "サーバディレクトリ: $(pwd)"
(cat | wine bedrock_server_mod.exe) 2>&1
