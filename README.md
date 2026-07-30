# ⏱️ Aplicación de Cronómetro en Flutter

Una aplicación de cronómetro moderna, funcional y fácil de usar, construida con Flutter 3.7.2+. Perfecto para rastrear el tiempo que dedicas a diferentes actividades.

## ✨ Características Principales

### 📊 Cronómetro
- **Interfaz clara y grande** - Fácil de leer y usar
- **Controles simples** - Play/Pause y Reset
- **Precisión en milisegundos** - Cronometración exacta
- **Estado visual** - Indicador de corriendo/pausado

### 📋 Historial Completo
- **Guardado automático** - Todos los cronómetros se guardan
- **Títulos personalizados** - Describe qué estabas haciendo
- **Categorización** - Organiza por tipo de actividad (Trabajo, Estudio, etc.)
- **Notas adicionales** - Agrega detalles a cada registro
- **Búsqueda** - Encuentra actividades rápidamente
- **Filtros por categoría** - Visualiza solo lo que necesitas

### 📈 Estadísticas
- **Total de actividades** - Cuántas veces has cronometrado
- **Tiempo total** - Suma de todo el tiempo registrado
- **Promedio por actividad** - Tiempo promedio
- **Actividad más larga** - Tu récord personal

### 💾 Persistencia de Datos
- **Base de datos local** - Usa Hive para guardar sin conexión
- **Sincronización automática** - Los cambios se guardan al instante
- **Sin límite de registros** - Mantén todo tu historial

## 🚀 Primeros Pasos

### Instalación

1. **Clona o descarga el proyecto**
   ```bash
   cd tiktac_app
   ```

2. **Instala las dependencias**
   ```bash
   flutter pub get
   ```

3. **Genera los archivos necesarios (Hive)**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Ejecuta la app**
   ```bash
   flutter run
   ```

## 📱 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── models/
│   └── stopwatch_entry.dart  # Modelo de datos
├── providers/
│   └── stopwatch_provider.dart  # Gestión de estado
├── services/
│   └── stopwatch_service.dart   # Lógica de base de datos
└── screens/
    ├── home_screen.dart      # Pantalla principal
    └── widgets/
        ├── stopwatch_display.dart    # Display del tiempo
        ├── control_buttons.dart      # Botones de control
        └── save_dialog.dart          # Diálogo para guardar
```

## 🛠️ Tecnologías Utilizadas

- **Flutter 3.7.2+** - Framework UI
- **Dart** - Lenguaje de programación
- **Provider** - Gestión de estado
- **Hive** - Base de datos local
- **Material 3** - Diseño de UI moderna

## 📝 Uso de la Aplicación

### Iniciar un Cronómetro
1. Abre la pestaña **⏱️ Cronómetro**
2. Presiona el botón **▶️ Play** para iniciar
3. Presiona **⏸️ Pause** para pausar en cualquier momento
4. Presiona **⏹️ Stop** para reiniciar

### Guardar una Actividad
1. Después de cronometrar, aparecerá el botón **Guardar Actividad**
2. Completa el formulario:
   - **Título**: Describe qué estabas haciendo (ej: "Reunión con clientes")
   - **Categoría**: Selecciona el tipo (Trabajo, Estudio, Ejercicio, etc.)
   - **Notas**: (Opcional) Agrega detalles adicionales
3. Presiona **Guardar**

### Ver el Historial
1. Abre la pestaña **📋 Historial**
2. Todos tus registros aparecerán listados
3. **Busca** por título o categoría
4. **Filtra** usando las categorías disponibles
5. **Toca** un registro para ver más detalles
6. **Elimina** registros que ya no necesites

### Ver Estadísticas
- Desplázate hasta el final de la pestaña **📋 Historial**
- Verás tus estadísticas completas

## 🎨 Diseño y UX

- **Interfaz moderna** - Usa Material Design 3
- **Gradiente atractivo** - Fondo púrpura degradado
- **Botones grandes** - Fáciles de presionar
- **Colores intuitivos** - Verde para play, rojo para stop
- **Dark-friendly** - Se adapta al tema del sistema

## 🔒 Privacidad

- ✅ **Sin datos en la nube** - Todo se guarda localmente
- ✅ **Sin rastreo** - No recopilamos información
- ✅ **Totalmente privado** - Solo tú tienes acceso

## 🤖 Características Futuras (Ideas)

- Exportar a CSV/PDF
- Sincronización en la nube
- Recordatorios y alarmas
- Gráficas de productividad
- Temas personalizables
- Widget de escritorio

## 📄 Licencia

Este proyecto es de código abierto. Úsalo y modifícalo libremente.

## 🆘 Troubleshooting

### La app no compila
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Los datos no se guardan
- Verifica que tienes permisos de almacenamiento
- Intenta reiniciar la app
- En Android: Verifica los permisos en Configuración

### Rendimiento lento
- Usa `flutter run --release` para mejor rendimiento
- En el dispositivo físico suele ser más rápido que el emulador

---

**Hecho con ❤️ en Flutter**
