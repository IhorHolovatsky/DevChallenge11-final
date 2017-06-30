FROM microsoft/mssql-server-windows
SHELL ["powershell"]

COPY ./SqlScripts/ C:\\SqlScripts

RUN sqlcmd -Q 'CREATE DATABASE nservicebus_db'
RUN sqlcmd -d nservicebus_db -i C:\SqlScripts\Install.sql
