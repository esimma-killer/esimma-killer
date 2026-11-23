# ESIMMA Killer — Frontend Multiplataforma (Flutter)

Aplicacion cliente desarrollada en Flutter bajo el paradigma de base de codigo unica (**Single Codebase**) con soporte para Web, Android y Escritorio (Windows y Linux).

---

## 1. Arquitectura Modular

El codigo fuente dentro de `lib/` se divide en cuatro capas limpias y sencillas:

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart      # Constantes globales y URL base de la API
│   └── theme/
│       ├── app_colors.dart         # Paleta institucional UAA sobria y plana
│       └── app_theme.dart          # Configuracion de tema claro y oscuro
├── data/
│   └── repositories/
│       └── campus_repository.dart  # Repositorio de datos de campus (preparado para HTTP)
├── domain/
│   └── entities/
│       └── campus_info.dart        # Entidad de dominio para los nodos de campus
├── presentation/
│   ├── screens/
│   │   └── home_placeholder_screen.dart # Pantalla base responsiva inicial
│   └── widgets/
│       └── campus_status_card.dart      # Tarjeta plana de estado de campus
└── main.dart                       # Punto de entrada de la aplicacion
```

---

## 2. Lineamientos de Diseno

- **Estetica institucional sobria y plana:** Uso de colores solidos sin gradientes, sin colores chillones y sin sombras o elevaciones 3D (`elevation: 0`).
- **Diseno responsivo:** Uso de `LayoutBuilder` y `ConstrainedBox` para adaptar la vista automaticamente a pantallas moviles y monitores de escritorio.

---

## 3. Comandos de Ejecucion y Verificacion

Desde el directorio `frontend/`:

1. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

2. **Ejecutar analisis estatico (linter):**
   ```bash
   flutter analyze
   ```

3. **Ejecutar pruebas unitarias de widgets:**
   ```bash
   flutter test
   ```

4. **Ejecutar la aplicacion por plataforma:**
   - **Web (Chrome):**
     ```bash
     flutter run -d chrome
     ```
   - **Escritorio (Windows):**
     ```bash
     flutter run -d windows
     ```
   - **Movil (Emulador o dispositivo Android):**
     ```bash
     flutter run -d android
     ```
