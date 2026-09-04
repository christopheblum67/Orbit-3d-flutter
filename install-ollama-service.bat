@echo off
REM ============================================================
REM  Installation du service Ollama (demarrage automatique)
REM  Lancez ce fichier en ADMIN :
REM    clic droit -> "Executer en tant qu'administrateur"
REM ============================================================
setlocal enabledelayedexpansion

set "OLLAMA_EXE=C:\Users\utilisateur\AppData\Local\Programs\Ollama\ollama.exe"
set "HOST_VERIF=http://localhost:11434/api/version"

echo.
echo ============================================================
echo   Installation du service Ollama - demarrage automatique
echo ============================================================
echo.

REM ---- 0. Verification des droits admin ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Ce script doit etre lance en tant qu'ADMINISTRATEUR.
    echo          Clic droit sur le fichier -^^> "Executer en tant qu'administrateur"
    echo.
    pause
    exit /b 1
)
echo [OK] Droits administrateur confirmes.
echo.

REM ---- 1. Verification que l'executable Ollama existe ----
if not exist "%OLLAMA_EXE%" (
    echo [ERREUR] Ollama introuvable : %OLLAMA_EXE%
    echo          Verifiez le chemin d'installation.
    echo.
    pause
    exit /b 1
)
echo [OK] Ollama trouve : %OLLAMA_EXE%
echo.

REM ---- 2. Arret du serveur manuel (libere le port 11434) ----
echo [..] Arret de l'instance manuelle d'Ollama (si elle tourne)...
taskkill /IM ollama.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
echo [OK] Instance manuelle arretee.
echo.

REM ---- 3. Suppression d'un eventuel service Ollama existant ----
sc.exe delete Ollama >nul 2>&1
timeout /t 1 /nobreak >nul
echo [OK] Ancien service Ollama supprime (s'il existait).
echo.

REM ---- 4. Creation du service (demarrage automatique) ----
echo [..] Creation du service Ollama...
sc.exe create Ollama binPath= "%OLLAMA_EXE% serve" start= auto
if %errorlevel% neq 0 (
    echo [ERREUR] Echec de la creation du service.
    echo.
    pause
    exit /b 1
)
echo [OK] Service Ollama cree (start= auto).
echo.

REM ---- 5. Demarrage immediat du service ----
echo [..] Demarrage du service Ollama...
sc.exe start Ollama
timeout /t 5 /nobreak >nul
echo.

REM ---- 6. Verification - etat du service ----
echo --- Etat du service ---
sc.exe query Ollama | findstr /i "STATE"
echo.

REM ---- 7. Verification - le serveur repond ----
echo --- Test du serveur HTTP ---
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:11434/api/version' -UseBasicParsing -TimeoutSec 5; Write-Host ('[OK] Serveur repond : ' + $r.Content) } catch { Write-Host ('[ERREUR] Serveur injoignable : ' + $_.Exception.Message) }"
echo.

echo ============================================================
echo   Termine. Le service Ollama demarre automatiquement au boot.
echo   Ne fermez pas ceci si une erreur est affichee.
echo ============================================================
echo.
pause
endlocal
