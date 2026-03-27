#!/usr/bin/env sh

set -e

# コンソール幅
stty size cols 80 || true

# Pterodactyl 標準の作業ディレクトリに合わせる
cd /home/container

# 環境変数
export HOME=/home/container
export WINEPREFIX=/home/container/.wine
export XDG_RUNTIME_DIR=/home/container/.tmp

export LANG=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja
export LC_ALL=ja_JP.UTF-8
export TERM=xterm-256color
export DISPLAY=:0

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

# 一時ディレクトリ
mkdir -p "$XDG_RUNTIME_DIR"

# Xvfb 起動（既に動いていたら失敗しても無視）
Xvfb :0 -screen 0 1024x768x16 >/tmp/xvfb.log 2>&1 || true
sleep 2

# Wine 初期化（ハング対策付き）
if [ ! -d "$WINEPREFIX" ]; then
    echo "Wine 環境を初期化中..."

    mkdir -p "$WINEPREFIX"

    TIMEOUT=120
    xvfb-run -a sh -c "timeout ${TIMEOUT} wineboot --init || true"

    if pgrep wineserver >/dev/null 2>&1; then
        echo "wineserver を終了します..."
        wineserver -k || true
        sleep 2
    fi

    if [ -d "$WINEPREFIX/drive_c" ]; then
        echo "Wine 初期化完了 (drive_c 確認済み)"
    else
        echo "警告: Wine prefix に drive_c が見つかりません。続行します。"
    fi

    echo ".NET 10 と Visual C++ をインストール中..."
    xvfb-run -a winetricks -q dotnet10 || echo "dotnet10 インストールに失敗しました"
    xvfb-run -a winetricks -q vcrun2022 || echo "vcrun2022 インストールに失敗しました"
    echo "ランタイムインストール処理完了"
fi

# Pterodactyl の割り当てポートを Bedrock に反映
BEDROCK_PORT="${SERVER_PORT:-${SERVER_PORT_1:-${PORT:-19132}}}"

if [ -f server.properties ]; then
  sed -i "s/^server-port=.*/server-port=${BEDROCK_PORT}/" server.properties 2>/dev/null || true
else
  cat > server.properties <<EOF
server-port=${BEDROCK_PORT}
gamemode=survival
difficulty=easy
max-players=10
EOF
fi

echo "Using Bedrock server-port=${BEDROCK_PORT}"

# LeviLamina インストール
if [ ! -f "bedrock_server_mod.exe" ]; then
    echo "LeviLamina をインストール中..."

    if [ -n "$GITHUB_MIRROR_URL" ]; then
        lip config set github_proxy "$GITHUB_MIRROR_URL"
        echo "GitHub ミラー: $GITHUB_MIRROR_URL"
    fi

    if [ -n "$GO_MODULE_PROXY_URL" ]; then
        lip config set go_module_proxy "$GO_MODULE_PROXY_URL"
        echo "Go Module Proxy: $GO_MODULE_PROXY_URL"
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
echo "Wine バージョン:"
wine --version || echo "wine --version 取得失敗"

# Pterodactyl 互換の起動（標準入力をパイプ）
(cat | wine bedrock_server_mod.exe) 2>&1
