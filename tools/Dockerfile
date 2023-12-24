# syntax=docker/dockerfile:1
FROM jetbrains/teamcity-agent:latest

USER root

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh && \
    apt-get update && \
    apt-get install -y wget apt-transport-https software-properties-common && \
    ../tests/pwshake.Tests.ps1 -Group public /etc/os-release && \
    wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    pwsh --version

WORKDIR /workdir

USER buildagent

ENTRYPOINT [ "/entrypoint.sh" ]
