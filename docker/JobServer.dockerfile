FROM microsoft/windowsservercore
SHELL ["powershell"]

COPY ./WindowsService/ C:\\WindowsService


ENTRYPOINT C:\WindowsService\NServiceBus.Host.exe
