FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# 必要パッケージ
RUN apt-get update && apt-get install -y \
    ca-certificates curl wget gnupg \
    wine64 winbind cabextract p7zip-full \
    xvfb winetricks \
    libicu-dev libkrb5-3 zlib1g \
    unzip procps \
    && rm -rf /var/lib/apt/lists/*

# .NET (Linux) ランタイム 10.x をインストール
# ※実際のバージョン/URLは MS 公式に合わせて調整
RUN mkdir -p /usr/share/dotnet \
    && cd /usr/share/dotnet \
    && wget -O dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/xxx/dotnet-runtime-10.0.0-linux-x64.tar.gz \
    && tar -xzf dotnet.tar.gz \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

# lip (Linux ネイティブ) をインストール
RUN curl -L https://github.com/LiteLDev/lip/releases/latest/download/lip-linux-x64.tar.gz -o /tmp/lip.tar.gz \
    && mkdir -p /opt/lip \
    && tar -xzf /tmp/lip.tar.gz -C /opt/lip \
    && ln -s /opt/lip/lip /usr/local/bin/lip \
    && rm /tmp/lip.tar.gz

# 作業ディレクトリ
WORKDIR /home/container

# entrypoint.sh をコピー
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV PTERODACTYL=true
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
