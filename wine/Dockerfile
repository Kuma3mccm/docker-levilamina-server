FROM ghcr.io/liteldev/levilamina-server:latest-wine

# 日本語ロケール + .NET(Linux) + lip(Linux) を追加
USER root

RUN apt-get update && apt-get install -y \
    locales ca-certificates curl wget xz-utils libicu-dev unzip \
    && sed -i 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen ja_JP.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8

# Windows向けPython 3.11 (Embeddable) を /usr/local/wine-python に用意
RUN mkdir -p /usr/local/wine-python \
    && curl -L https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip -o /tmp/python.zip \
    && unzip /tmp/python.zip -d /usr/local/wine-python \
    && rm /tmp/python.zip \
    && cd /usr/local/wine-python \
    && curl -L https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && sed -i 's/#import site/import site/' python311._pth

# Linux 向け .NET Runtime 10.x をインストール（URL は実環境に合わせて修正）
RUN mkdir -p /usr/share/dotnet \
    && cd /usr/share/dotnet \
    && wget -O dotnet.tar.gz https://builds.dotnet.microsoft.com/dotnet/Runtime/10.0.5/dotnet-runtime-10.0.5-linux-x64.tar.gz \
    && tar -xzf dotnet.tar.gz \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

# lip (Linux ネイティブ) をインストール
RUN curl -L https://github.com/futrime/lip/releases/download/v0.34.4/lip-0.34.4-linux-x64.tar.xz -o /tmp/lip.tar.xz \
    && mkdir -p /opt/lip-linux \
    && tar -xJf /tmp/lip.tar.xz -C /opt/lip-linux \
    && chmod +x /opt/lip-linux/lip \
    && ln -sf /opt/lip-linux/lip /usr/local/bin/lip \
    && rm /tmp/lip.tar.xz

# /home/container 用 entrypoint を上書き
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

USER 1000
