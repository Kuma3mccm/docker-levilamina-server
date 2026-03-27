FROM mcr.microsoft.com/windows/servercore:ltsc2022@sha256:c7c591fe3a010bc641906723ad583ffe2fc14b472de6e6453ea26eaa3689d16e

ENV DOTNET_VERSION=10.0.5
ENV LIP_VERSION=v0.34.4

ADD https://aka.ms/vc14/vc_redist.x64.exe vcredist.exe
ADD https://builds.dotnet.microsoft.com/dotnet/Runtime/${DOTNET_VERSION}/dotnet-runtime-${DOTNET_VERSION}-win-x64.exe dotnet-runtime.exe

RUN vcredist.exe /install /quiet /norestart && del vcredist.exe
RUN dotnet-runtime.exe /install /quiet /norestart && del dotnet-runtime.exe

ADD https://github.com/futrime/lip/releases/download/${LIP_VERSION}/lip-${LIP_VERSION}-win-x64.zip lip.zip

RUN mkdir "\Program Files\lip" \
    && cd "\Program Files\lip" \
    && tar -x -f \lip.zip \
    && del \lip.zip \
    && mklink \Windows\lip.exe "\Program Files\lip\lip.exe"

COPY entrypoint.cmd /Windows/entrypoint.cmd

WORKDIR /data

ENTRYPOINT ["entrypoint.cmd"]
