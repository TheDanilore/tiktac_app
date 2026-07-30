# 📦 Guía Completa de Instalación

## ✅ Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

1. **Flutter 3.7.2 o superior**
   ```bash
   flutter --version
   ```
   
   Si no lo tienes, descárgalo desde: https://flutter.dev/docs/get-started/install

2. **Dart** (viene con Flutter)
   ```bash
   dart --version
   ```

3. **Android Studio** o **Xcode** (para emulador)
   - Android: Descarga desde https://developer.android.com/studio
   - iOS: Xcode desde Mac App Store

## 🚀 Instalación Paso a Paso

### 1. Prepara el entorno Flutter

```bash
# Verifica que Flutter está correctamente instalado
flutter doctor

# Deberías ver ✓ en: Flutter, Dart, Android toolchain (si es Android), Xcode (si es iOS)
```

Si hay problemas, ejecuta:
```bash
flutter doctor --android-licenses
# Acepta todos los términos
```

### 2. Descarga o clona el proyecto

**Opción A: Descarga el ZIP**
- Descarga el archivo ZIP del proyecto
- Extrae en una carpeta

**Opción B: Clona desde Git (si tienes el repositorio)**
```bash
git clone <tu-repositorio>
cd cronometro_app
```

### 3. Instala las dependencias

```bash
cd cronometro_app
flutter pub get
```

Esto descargará todas las librerías necesarias (Provider, Hive, etc.)

### 4. Genera los archivos de Hive

Este paso es **IMPORTANTE** para que la base de datos funcione:

```bash
flutter pub run build_runner build
```

O si tienes conflictos:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Verás output similar a:
```
[INFO] Building new asset graph completed, took 1284ms
[INFO] Checking for updates took 267ms
[INFO] Running build completed, took 2859ms
[INFO] Caching finalized dependency graph completed, took 45ms
```

### 5. Ejecuta la aplicación

**En emulador Android:**
```bash
flutter run
```

**En dispositivo Android conectado:**
```bash
flutter run
```

**En emulador iOS (solo Mac):**
```bash
open -a Simulator
flutter run -d all
```

**En dispositivo iOS (solo Mac):**
```bash
flutter run -d <device-id>
```

**En web (experimental):**
```bash
flutter run -d chrome
```

## 🔧 Solución de Problemas

### Error: "flutter: command not found"

```bash
# En macOS/Linux
export PATH="$PATH:$HOME/flutter/bin"

# Luego agrega esto a tu ~/.bashrc o ~/.zshrc para permanentemente
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Error: "Gradle build failed"

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "Hive box is not open"

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter clean
flutter pub get
flutter run
```

### Error: "SDK version mismatch"

Edita `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 35
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 35
    }
}
```

### El emulador es muy lento

Usa **release mode** para mejor rendimiento:
```bash
flutter run --release
```

O usa un dispositivo físico, mucho más rápido.

## 🎯 Verificación Final

Después de instalar, verifica que todo funciona:

1. ✅ La app abre correctamente
2. ✅ El cronómetro cuenta los segundos
3. ✅ Puedes presionar Play/Pause/Stop
4. ✅ Puedes guardar una actividad
5. ✅ La actividad aparece en el historial
6. ✅ Aparecen las estadísticas

## 📝 Notas Adicionales

### Estructura de directorios esperada:

```
cronometro_app/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── services/
│   └── screens/
├── pubspec.yaml
├── README.md
└── INSTALACION.md
```

### Configuración de idioma

El proyecto está en español. Para cambiar:
- Busca strings en los archivos `.dart`
- Modifica directamente en el código
- Considera usar localization en futuros updates

### Performance tips

1. Usa `--release` en producción:
   ```bash
   flutter run --release
   ```

2. Compila APK para Android:
   ```bash
   flutter build apk --release
   ```

3. Compila IPA para iOS (solo Mac):
   ```bash
   flutter build ios --release
   ```

## 🆘 ¿Aún tienes problemas?

Ejecuta esto para generar un reporte detallado:
```bash
flutter doctor -v > flutter_doctor.txt
# Luego abre flutter_doctor.txt para analizar
```

**Comandos útiles para limpiar:**
```bash
# Limpia compilaciones
flutter clean

# Reinstala dependencias
flutter pub get

# Regenera archivos de build
flutter pub run build_runner clean
flutter pub run build_runner build

# Todo de una vez
flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
```

---

**¡Listo! Ya deberías tener la app funcionando 🎉**

Si todo va bien, verás la pantalla principal del cronómetro con el diseño púrpura moderno.
