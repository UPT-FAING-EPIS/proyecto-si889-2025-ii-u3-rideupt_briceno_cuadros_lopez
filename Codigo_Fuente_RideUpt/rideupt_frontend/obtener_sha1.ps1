# Script PowerShell para obtener SHA-1 automáticamente

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OBTENIENDO SHA-1 PARA FIREBASE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"

Write-Host "🔍 Buscando keytool..." -ForegroundColor Yellow

$keytoolPaths = @(
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jre\bin\keytool.exe",
    "C:\Program Files\Java\jdk-17\bin\keytool.exe",
    "C:\Program Files\Java\jdk-11\bin\keytool.exe",
    "C:\Program Files\Java\jdk1.8.0_301\bin\keytool.exe",
    "C:\Program Files\Java\jdk1.8.0_321\bin\keytool.exe"
)

$keytoolFound = $null

foreach ($path in $keytoolPaths) {
    if (Test-Path $path) {
        Write-Host "✅ Encontrado: $path" -ForegroundColor Green
        $keytoolFound = $path
        break
    }
}

if (-not $keytoolFound) {
    Write-Host ""
    Write-Host "❌ No se encontró keytool" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 SOLUCIONES:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Usa Android Studio:" -ForegroundColor White
    Write-Host "   - Abre el proyecto en Android Studio"
    Write-Host "   - Panel derecho: Gradle"
    Write-Host "   - android → Tasks → android → signingReport"
    Write-Host "   - Doble click y copia el SHA-1"
    Write-Host ""
    Write-Host "2. Busca keytool.exe manualmente:" -ForegroundColor White
    Write-Host "   - Explorador de archivos → Buscar 'keytool.exe'"
    Write-Host "   - Anota la ruta completa"
    Write-Host ""
    pause
    exit
}

Write-Host ""
Write-Host "🔑 Verificando debug.keystore..." -ForegroundColor Yellow

if (-not (Test-Path $debugKeystore)) {
    Write-Host ""
    Write-Host "❌ No se encontró debug.keystore en:" -ForegroundColor Red
    Write-Host "   $debugKeystore"
    Write-Host ""
    Write-Host "💡 Ejecuta 'flutter run' al menos una vez para generar el keystore" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit
}

Write-Host "✅ Keystore encontrado" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OBTENIENDO HUELLAS DIGITALES..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $output = & $keytoolFound -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android 2>&1
    
    Write-Host $output
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  📋 INSTRUCCIONES:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. COPIA el SHA1 de arriba (40 caracteres con ':')" -ForegroundColor Green
    Write-Host ""
    Write-Host "2. Ve a Firebase Console:" -ForegroundColor Green
    Write-Host "   https://console.firebase.google.com/project/rideupt/settings/general"
    Write-Host ""
    Write-Host "3. Scroll down → 'Apps para Android' → com.example.rideupt_app" -ForegroundColor Green
    Write-Host ""
    Write-Host "4. En 'Huellas digitales del certificado SHA':" -ForegroundColor Green
    Write-Host "   - Click 'Agregar huella digital'"
    Write-Host "   - Pega el SHA-1"
    Write-Host "   - Click 'Guardar'"
    Write-Host ""
    Write-Host "5. Descargar NUEVO google-services.json:" -ForegroundColor Green
    Write-Host "   - En la misma pantalla"
    Write-Host "   - Click en 'google-services.json'"
    Write-Host "   - Guardar archivo"
    Write-Host ""
    Write-Host "6. Reemplazar archivo:" -ForegroundColor Green
    Write-Host "   F:\AppRideUpt\rideupt_app\android\app\google-services.json"
    Write-Host ""
    Write-Host "7. Habilitar Google Sign-In:" -ForegroundColor Green
    Write-Host "   https://console.firebase.google.com/project/rideupt/authentication/providers"
    Write-Host "   - Click 'Google' → Habilitar → Guardar"
    Write-Host ""
    Write-Host "8. Rebuild:" -ForegroundColor Green
    Write-Host "   cd F:\AppRideUpt\rideupt_app"
    Write-Host "   flutter clean"
    Write-Host "   flutter run"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Extraer solo el SHA1 para facilitar copia
    $sha1Line = $output | Select-String "SHA1:"
    if ($sha1Line) {
        Write-Host ""
        Write-Host "🎯 SHA-1 PARA COPIAR:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host $sha1Line -ForegroundColor Green
        Write-Host ""
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ Error al ejecutar keytool: $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")




