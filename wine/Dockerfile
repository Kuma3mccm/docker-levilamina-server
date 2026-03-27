FROM ghcr.io/liteldev/levilamina-server:latest-wine

# 日本語ロケール + .NET(Linux) + lip(Linux) を追加
USER root

RUN apt-get update && apt-get install -y locales ca-certificates curl wget \
    && sed -i 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen ja_JP.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8

# Linux 向け .NET Runtime 10.x をインストール（URL は実環境に合わせて修正）
RUN mkdir -p /usr/share/dotnet \
    && cd /usr/share/dotnet \
    && wget -O dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/xxx/dotnet-runtime-10.0.0-linux-x64.tar.gz \
    && tar -xzf dotnet.tar.gz \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

# lip (Linux ネイティブ) をインストール
RUN curl -L https://github.com/LiteLDev/lip/releases/latest/download/lip-linux-x64.tar.gz -o /tmp/lip.tar.gz \
    && mkdir -p /opt/lip-linux \
    && tar -xzf /tmp/lip.tar.gz -C /opt/lip-linux \
    && ln -sf /opt/lip-linux/lip /usr/local/bin/lip \
    && rm /tmp/lip.tar.gz

# /home/container 用 entrypoint を上書き
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

USER 1000
