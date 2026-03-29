#!/usr/bin/env sh

set -e
stty cols 160 rows 40 || true

cd /home/container

export HOME=/home/container
export WINEPREFIX=/home/container/.wine
export XDG_RUNTIME_DIR=/home/container/.tmp

export LANG=ja_JP.UTF-8
export LANGUAGE=ja_JP:ja
export LC_ALL=ja_JP.UTF-8
export TERM=xterm-256color

VERSION="${VERSION:-LATEST}"

echo "[0] === LeviLamina JP (Pterodactyl /home/container 版) ==="
echo "[0] 日時: $(date)"
echo "[0] バージョン: ${VERSION}"
echo "[0] EULA: ${EULA:-未設定}"

if [ "$EULA" != "TRUE" ]; then
    echo "[0] エラー: EULA=TRUE が必要です"
    exit 1
fi

echo "[1] ディレクトリ準備..."
mkdir -p "$XDG_RUNTIME_DIR" "$WINEPREFIX" || true

# Wine 初期化
if [ ! -d "$WINEPREFIX/drive_c" ]; then
    echo "[2] Wine 環境を初期化中..."
    set +e
    timeout 60 wineboot --init >/tmp/wineboot.log 2>&1
    WB_CODE=$?
    set -e
    echo "[2] wineboot 終了コード: $WB_CODE"
    sed -e '1,30p' /tmp/wineboot.log 2>/dev/null || true
    wineserver -k || true
fi

if [ -d "$WINEPREFIX/drive_c" ]; then
    echo "[2] Wine 初期化完了 (drive_c 確認済み)"
else
    echo "[2] 警告: drive_c がありませんが続行します"
fi

if [ ! -d "$WINEPREFIX/drive_c/Python" ]; then
    echo "[2.5] Python (Windows) 環境を構成中..."
    cp -r /usr/local/wine-python "$WINEPREFIX/drive_c/Python"
    # pipのインストールを実行
    wine cmd /c "C:\\Python\\python.exe C:\\Python\\get-pip.py" || true
    # レジストリにPATHを追加
    wine reg add "HKCU\\Environment" /v PATH /t REG_SZ /d "C:\\Python;C:\\Python\\Scripts;%PATH%" /f || true
fi

echo "[3] Bedrock server.properties のポート設定..."
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

echo "[3] Using Bedrock server-port=${BEDROCK_PORT}"

echo "[4] 自前 LeviLamina の存在確認..."
ls -la bedrock_server_mod.exe || { echo "[4] エラー: bedrock_server_mod.exe がありません"; exit 1; }

echo "[4.5] LeviStone の自動インストール確認..."
if [ ! -d "plugins/EndstoneRuntime/levistone" ]; then
    echo "[4.5] LeviStone を自動インストールしています..."
    mkdir -p plugins/EndstoneRuntime
    wine cmd /c "C:\\Python\\python.exe -m pip install levistone --target plugins/EndstoneRuntime" || echo "[4.5] 警告: pip install に失敗した可能性があります"
else
    echo "[4.5] LeviStone はインストール済みです"
fi

echo "[5] Wine バージョン確認..."
wine --version || echo "[5] wine --version 取得失敗"

echo "[6] === LeviLamina サーバ起動中 ==="
echo "[6] サーバディレクトリ: $(pwd)"

(cat | wine bedrock_server_mod.exe) 2>&1
