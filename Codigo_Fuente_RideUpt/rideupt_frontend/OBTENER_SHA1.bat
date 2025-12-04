@echo off
echo ========================================
echo   OBTENIENDO SHA-1 PARA GOOGLE SIGN-IN
echo ========================================
echo.

cd android

echo Ejecutando gradlew signingReport...
echo.

call gradlew.bat signingReport > sha1_output.txt 2>&1

echo.
echo ========================================
echo BUSCANDO SHA-1 EN LA SALIDA...
echo ========================================
echo.

findstr /C:"SHA1:" sha1_output.txt

echo.
echo ========================================
echo INSTRUCCIONES:
echo ========================================
echo.
echo 1. COPIA el SHA-1 que aparece arriba
echo    (Los 40 caracteres despues de "SHA1:")
echo.
echo 2. Ve a Firebase Console:
echo    https://console.firebase.google.com
echo.
echo 3. Project Settings - Your apps - Android
echo.
echo 4. Add fingerprint - Pega el SHA-1
echo.
echo 5. Download google-services.json NUEVO
echo.
echo 6. Reemplaza android/app/google-services.json
echo.
echo 7. Ejecuta: flutter clean && flutter run
echo.
echo ========================================
echo.
echo Output completo guardado en: android\sha1_output.txt
echo.

pause




