@echo off
setlocal enabledelayedexpansion

rem Caminhos "Iniciais e Finais" de todo o processo, onde valida o arquivo .rar até final onde será salvo os arquivo do BD.
set "pastaInicial=C:\BKP-SGH"
set "pastaFinal=E:\work\banco"

set "logArquivos=%pastaInicial%\log_OldFile_RestorHomolog.txt"
set "logGeral=%pastaInicial%\GeneralLog_RestorHomolog.txt"

call :atualizarTimeStamp
echo !TIMESTAMP! :: [INFO] Bem-vindo ao Extrator de Arquivos "*.rar".
echo ::

rem Verifica se o caminho da pastaInicial existe (Não tem como gerar o log, pois ele gera no caminho que não existe.)
if not exist "%pastaInicial%" (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [ERROR] Caminho da pasta "%pastaInicial%" nao existe.
    echo !TIMESTAMP! :: [INFO] Edite o ".bat" e altere o caminho da variavel "pastaInicial" para algo existente...
    echo ::
    pause
    exit /b
)

rem Verifica se a pastaFinal existe
if not exist "!pastaFinal!" (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [ERROR] Pasta de destino final "!pastaFinal!" nao encontrada. >> "%logGeral%"
    echo !TIMESTAMP! :: [ERROR] Pasta de destino final "!pastaFinal!" nao encontrada.
    echo !TIMESTAMP! :: [INFO] Edite o ".bat" e altere o caminho da variavel "pastaFinal" para algo existente...
    pause
    exit /b 1
)

rem Valida o caminho do WinRAR (64 bits ou 32 bits) antes de prosseguir.
set "caminhoWinRAR="
if exist "%ProgramFiles%\WinRAR\WinRAR.exe" (
    set "caminhoWinRAR=%ProgramFiles%\WinRAR\WinRAR.exe"
) else if exist "%ProgramFiles(x86)%\WinRAR\WinRAR.exe" (
    set "caminhoWinRAR=%ProgramFiles(x86)%\WinRAR\WinRAR.exe"
) else (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [ERROR] Caminho padrao do WinRAR [64 bits ou 32 bits] nao foi encontrado. >> "%logGeral%"
    echo !TIMESTAMP! :: [ERROR] Caminho padrao do WinRAR [64 bits ou 32 bits] nao foi encontrado.
    exit /b
)

rem Valida a existencia de arquivos .rar no caminho especificado antes de prosseguir
dir "%pastaInicial%\*.rar" >nul 2>&1
if errorlevel 1 (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [ABORTADO] Nenhum arquivo .rar encontrado na pasta especificada. >> "%logGeral%"
    echo !TIMESTAMP! :: [ABORTADO] Nenhum arquivo .rar encontrado na pasta especificada.
    exit /b
)

rem Verifica se o log de arquivos existe e lê o último arquivo descompactado
if exist "%logArquivos%" (
    for /f "tokens=*" %%A in ('type "%logArquivos%"') do set "ultimoArquivoDescompactado=%%A"
) else (
    set "ultimoArquivoDescompactado=null"
)

rem Procura por arquivos .rar dentro da pasta especificada e valida 
for %%I in ("%pastaInicial%\*.rar") do (
    set "arquivoRAR=%%I"
    set "diretorio=%%~dpI"

    rem Compara com o último arquivo descompactado
    if "!ultimoArquivoDescompactado!" == "%%~nI" (
        call :atualizarTimeStamp
        echo !TIMESTAMP! :: [ABORTADO] O arquivo "%%~nI" ja foi descompactado anteriormente. >> "%logGeral%"
        echo !TIMESTAMP! :: [ABORTADO] O arquivo "%%~nI" ja foi descompactado anteriormente.
        exit /b
    ) else (
        rem Valida a existência da pasta "work" e a exclui se ela existir
        if exist "%pastaInicial%\work\" (
            call :atualizarTimeStamp
            echo !TIMESTAMP! :: [INFO] A pasta "work" foi encontrada no diretorio e foi excluida. >> "%logGeral%"
            echo !TIMESTAMP! :: [INFO] A pasta "work" foi encontrada no diretorio e foi excluida.
            rmdir /s /q "%pastaInicial%\work\"
        )

        rem Executa comando no WinRAR
        call :atualizarTimeStamp
        echo !TIMESTAMP! :: [INICIADO] Descompactando arquivo "%%~nI". >> "%logGeral%"
        echo !TIMESTAMP! :: [INICIADO] Descompactando arquivo "%%~nI".
        echo !TIMESTAMP! :: [INFO] Aguarde o processo com paciencia... 
        "%caminhoWinRAR%" x "!arquivoRAR!" "!diretorio!"

        rem Verifica se a descompactação foi bem-sucedida
        if !errorlevel! == 0 (
            call :atualizarTimeStamp
            echo !TIMESTAMP! :: [SUCESSO] Descompactacao de "%%~nI" concluida com sucesso. >> "%logGeral%"
            echo !TIMESTAMP! :: [SUCESSO] Descompactacao de "%%~nI" concluida com sucesso.
            
            echo %%~nI>> "%logArquivos%"
            set "ultimoArquivoDescompactado=%%~nI"

            rem Remove todos os arquivos .rar no pastaInicial após o sucesso da descompactação
            del /q "%pastaInicial%\*.rar"
        ) else (
            call :atualizarTimeStamp
            echo !TIMESTAMP! :: [ERROR] Erro !errorlevel! na descompactacao do arquivo "%%~nI". >> "%logGeral%"
            echo !TIMESTAMP! :: [ERROR] Erro !errorlevel! na descompactacao do arquivo "%%~nI".
            exit /b
        )
    )
)

rem Inicio do Importador do "*.fbk". (Se chegou até aqui, o BKP deu OK)
call :atualizarTimeStamp
echo ::
echo !TIMESTAMP! :: [INFO] Extrator de arquivos finalizado.
echo ::
echo !TIMESTAMP! :: [INFO] Bem-vindo ao Importador do "*.fbk".
echo ::

set "caminhoGbak="
set "pastaInicialBanco=%pastaInicial%\work\banco"

REM Loop por todas as pastas que começam com "Firebird_" (Qualquer versão do Firebird) para encontrar o caminho do gbak.exe
for /d %%D in ("C:\Program Files\Firebird\Firebird_*") do (
    if exist "%%D\gbak.exe" (
        set "caminhoGbak=%%D\gbak.exe"
        goto :Encontrado
    )
)
:Encontrado
if not defined caminhoGbak (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [ERROR] Caminho do arquivo "gbak.exe" não foi encontrada. >> "%logGeral%"
    echo !TIMESTAMP! :: [ERROR] Caminho do arquivo "gbak.exe" não foi encontrada.
    exit /b
)

REM Valida a existencia da pasta com os arquivos .fbk
if not exist "%pastaInicialBanco%" (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [ERROR] Caminho da pasta "...\work\banco" não foi encontrada. >> "%logGeral%"
    echo !TIMESTAMP! :: [ERROR] Caminho da pasta "...\work\banco" não foi encontrada.
    exit /b
)

REM Loop para armazenar os nomes dos arquivos .fbk
set "arquivo1="
set "arquivo2="
set "arquivo3="
set "contador=0"

rem Cria uma lista temporária para armazenar os arquivos em ordem alfabética
set "listaArquivos="
for /f "delims=" %%F in ('dir /b /on "%pastaInicialBanco%\*"') do (
    set /a contador+=1
    if !contador! equ 1 set "arquivo1=%%~nF.fbk"
    if !contador! equ 2 set "arquivo2=%%~nF.fbk"
    if !contador! equ 3 set "arquivo3=%%~nF.fbk"
)

rem Setando o nome de cada bd para os respectivos arquivos
set "nomeDoBanco1=SGHDADOS2.830"
set "nomeDoBanco2=SGHIMAGENS.GDB"
set "nomeDoBanco3=SGHLOG.GDB"

rem Setando o caminho correto de restauração para cada arquivo
set "caminhoBdRestor1=%pastaInicialBanco%\%nomeDoBanco1%"
set "caminhoBdRestor2=%pastaInicialBanco%\%nomeDoBanco2%"
set "caminhoBdRestor3=%pastaInicialBanco%\%nomeDoBanco3%"

rem Exibe os arquivos encontrados mais seus caminhos
call :atualizarTimeStamp
echo !TIMESTAMP! :: [INFO] 1 Arquivo: "!arquivo1!" -CaminhoRestor: "%caminhoBdRestor1%"
echo !TIMESTAMP! :: [INFO] 2 Arquivo: "!arquivo2!" -CaminhoRestor: "%caminhoBdRestor2%"
echo !TIMESTAMP! :: [INFO] 3 Arquivo: "!arquivo3!" -CaminhoRestor: "%caminhoBdRestor3%"
echo ::

goto :IniciarFuncaoExec

rem Função para executar o comando gbak e verificar o sucesso ou erro
:executaRestauracao
set "arquivo=%~1"
set "caminhoRestauracao=%~2"

call :atualizarTimeStamp
echo !TIMESTAMP! :: [INICIADO] Restaurando o arquivo "!arquivo!". >> "%logGeral%"
echo !TIMESTAMP! :: [INICIADO] Restaurando o arquivo "!arquivo!".
echo !TIMESTAMP! :: [INFO] Aguarde o processo com paciencia... 

rem Codigo final de execução
"%caminhoGbak%" -c -v -user SYSDBA -pass masterkey "%pastaInicialBanco%\!arquivo!" "%caminhoRestauracao%" 2>&1

if errorlevel 1 (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [ERROR] Erro ao restaurar o arquivo "!arquivo!". >> "%logGeral%"
    echo !TIMESTAMP! :: [ERROR] Erro ao restaurar o arquivo "!arquivo!".
    exit /b 1
) else (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [SUCESSO] Restauracao do arquivo "!arquivo!" concluida com sucesso. >> "%logGeral%"
    echo !TIMESTAMP! :: [SUCESSO] Restauracao do arquivo "!arquivo!" concluida com sucesso.

    rem Apaga o arquivo importado após sucesso
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [INFO] Arquivo "!arquivo!" removido.
    del /q "%pastaInicialBanco%\!arquivo!"
)
exit /b 0

:IniciarFuncaoExec
rem Executa as restaurações uma por vez
call :executaRestauracao "!arquivo1!" "!caminhoBdRestor1!"
if errorlevel 1 exit /b 1

call :executaRestauracao "!arquivo2!" "!caminhoBdRestor2!"
if errorlevel 1 exit /b 1

call :executaRestauracao "!arquivo3!" "!caminhoBdRestor3!"
if errorlevel 1 exit /b 1

goto :IniciarFuncaoCopiaFinal

rem Inicio da cópia para a pasta final.
rem Função para copiar arquivos finais e verificar o sucesso ou erro
:copiaFinal
set "nomeDoBanco=%~1"

call :atualizarTimeStamp
echo !TIMESTAMP! :: [INICIADO] Copiando "!nomeDoBanco!" para a pasta de destino final. >> "%logGeral%"
echo !TIMESTAMP! :: [INICIADO] Copiando "!nomeDoBanco!" para a pasta de destino final.
copy /y "!pastaInicialBanco!\!nomeDoBanco!" "!pastaFinal!\!nomeDoBanco!"
if errorlevel 1 (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [ERROR] Falha ao copiar "!nomeDoBanco!". >> "%logGeral%"
    echo !TIMESTAMP! :: [ERROR] Falha ao copiar "!nomeDoBanco!".
    exit /b 1
) else (
    call :atualizarTimeStamp
    echo !TIMESTAMP! :: [SUCESSO] Arquivo "!nomeDoBanco!" copiado com sucesso. >> "%logGeral%"
    echo !TIMESTAMP! :: [SUCESSO] Arquivo "!nomeDoBanco!" copiado com sucesso.
)
exit /b 0

:IniciarFuncaoCopiaFinal
rem Executa as copias uma por vez
call :copiaFinal "!nomeDoBanco1!"
if errorlevel 1 exit /b 1

call :copiaFinal "!nomeDoBanco2!"
if errorlevel 1 exit /b 1

call :copiaFinal "!nomeDoBanco3!"
if errorlevel 1 exit /b 1

rem Se todas as cópias foram bem-sucedidas, exibe mensagem de sucesso
call :atualizarTimeStamp
echo !TIMESTAMP! :: [SUCESSO] Todos os arquivos foram copiados com sucesso. >> "%logGeral%"
echo !TIMESTAMP! :: [SUCESSO] Todos os arquivos foram copiados com sucesso.

call :atualizarTimeStamp
echo !TIMESTAMP! :: [SUCESSO] Processo geral concluido. >> "%logGeral%"
echo !TIMESTAMP! :: [SUCESSO] Processo geral concluido.

exit /b 0

rem Obter data, hora e segundos no formato desejado
:atualizarTimeStamp
for /f "tokens=1-6 delims=/:-. " %%a in ('echo %date% %time%') do set TIMESTAMP=%%a-%%b-%%c %%d:%%e:%%f
exit /b 0