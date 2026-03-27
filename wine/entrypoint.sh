#!/usr/bin/env sh

set -e

stty size cols 80 || true

cd /home/container

export HOME=/home/container
export WINEPREFIX=/home/container/.wine
export XDG_RUNTIME_DIR=/home/container/.tmp

export LANG=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja
export LC_ALL=ja_JP.UTF-8
export TERM=xterm-256color
export DISPLAY=:0

VERSION="${VERSION:-LATEST}"

echo "[0] === LeviLamina サーバー起動 (日本語対応版) ==="
echo "[0] ロケール: $LANG"
echo "[0] 日時: $(date)"
echo "[0] バージョン: ${VERSION}"
echo "[0] EULA: ${EULA:-未設定}"

if [ "$EULA" != "TRUE" ]; then
    echo "[0] エラー: EULA=TRUE が必要です"
    exit 1
fi

echo "[1] ディレクトリと環境変数準備中..."
mkdir -p "$XDG_RUNTIME_DIR" || echo "[1] XDG_RUNTIME_DIR 作成失敗"

echo "[2] Xvfb 起動試行..."
# Xvfb は失敗しても続行
Xvfb :0 -screen 0 1024x768x16 >/tmp/xvfb.log 2>&1 || echo "[2] Xvfb 起動失敗（無視して続行）"
sleep 2
echo "[2] Xvfb 起動処理完了"

if [ ! -d "$WINEPREFIX" ]; then
    echo "[3] Wine 環境を初期化中..."

    mkdir -p "$WINEPREFIX" || echo "[3] WINEPREFIX 作成失敗（${WINEPREFIX}）"

    TIMEOUT=60
    echo "[3] wineboot --init を ${TIMEOUT} 秒タイムアウト付きで実行..."
    set +e
    xvfb-run -a sh -c "timeout ${TIMEOUT} wineboot --init" >/tmp/wineboot.log 2>&1
    WB_CODE=$?
    set -e

    echo "[3] wineboot 終了コード: $WB_CODE"
    echo "[3] wineboot.log:"
    sed -e '1,50p' /tmp/wineboot.log 2>/dev/null || echo "[3] wineboot.log 読み込み失敗"

    if pgrep wineserver >/dev/null 2>&1; then
        echo "[3] wineserver を終了します..."
        wineserver -k || true
        sleep 2
    fi

    if [ -d "$WINEPREFIX/drive_c" ]; then
        echo "[3] Wine 初期化完了 (drive_c 確認済み)"
    else
        echo "[3] 警告: Wine prefix に drive_c が見つかりませんが続行します"
    fi

    echo "[4] .NET 10 と Visual C++ をインストール中..."
    set +e
    xvfb-run -a winetricks -q dotnet10 >/tmp/dotnet10.log 2>&1
    echo "[4] dotnet10 終了コード: $?"
    sed -e '1,20p' /tmp/dotnet10.log 2>/dev/null || true

    xvfb-run -a winetricks -q vcrun2022 >/tmp/vcrun2022.log 2>&1
    echo "[4] vcrun2022 終了コード: $?"
    sed -e '1,20p' /tmp/vcrun2022.log 2>/dev/null || true
    set -e
    echo "[4] ランタイムインストール処理完了（失敗していても続行）"
else
    echo "[3] 既存の WINEPREFIX が見つかりました (${WINEPREFIX})"
fi

echo "[5] Bedrock server.properties のポート設定..."

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

echo "[5] Using Bedrock server-port=${BEDROCK_PORT}"

echo "[6] LeviLamina インストール確認..."
if [ ! -f "bedrock_server_mod.exe" ]; then
    echo "[6] LeviLamina をインストール中..."

    if [ -n "$GITHUB_MIRROR_URL" ]; then
        lip config set github_proxy "$GITHUB_MIRROR_URL" || echo "[6] github_proxy 設定失敗"
        echo "[6] GitHub ミラー: $GITHUB_MIRROR_URL"
    fi

    if [ -n "$GO_MODULE_PROXY_URL" ]; then
        lip config set go_module_proxy "$GO_MODULE_PROXY_URL" || echo "[6] go_module_proxy 設定失敗"
        echo "[6] Go Module Proxy: $GO_MODULE_PROXY_URL"
    fi

    set +e
    if [ "$VERSION" = "LATEST" ]; then
        lip install github.com/LiteLDev/LeviLamina >/tmp/lip-install.log 2>&1
    else
        lip install github.com/LiteLDev/LeviLamina@"$VERSION" >/tmp/lip-install.log 2>&1
    fi
    LIP_CODE=$?
    set -e

    echo "[6] lip install 終了コード: $LIP_CODE"
    sed -e '1,50p' /tmp/lip-install.log 2>/dev/null || true

    if [ -n "$PACKAGES" ]; then
        echo "[6] 追加パッケージをインストール中: $PACKAGES"
        set +e
        lip install $PACKAGES >/tmp/lip-packages.log 2>&1
        echo "[6] 追加パッケージ 終了コード: $?"
        sed -e '1,50p' /tmp/lip-packages.log 2>/dev/null || true
        set -e
    fi

    echo "[6] LeviLamina インストール処理完了（失敗していてもログを確認してください）"
else
    echo "[6] LeviLamina は既にインストールされています"
fi

echo "[7] Wine バージョン確認..."
wine --version || echo "[7] wine --version 取得失敗"

echo "[8] === LeviLamina サーバ起動中 ==="
echo "[8] サーバディレクトリ: $(pwd)"
echo "[8] bedrock_server_mod.exe の存在確認:"
ls -la bedrock_server_mod.exe || echo "[8] bedrock_server_mod.exe が見つかりません"

echo "[9] サーバを起動します..."
(cat | wine bedrock_server_mod.exe) 2>&1
