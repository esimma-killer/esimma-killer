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
   - **Web (Chrome, solo desarrollo):**
     ```bash
     flutter run -d chrome --web-hostname=127.0.0.1 --web-port=8080
     ```
   - **Escritorio (Windows):**
     ```bash
     flutter run -d windows
     ```
   - **Movil (Emulador o dispositivo Android):**
     ```bash
     flutter run -d android
     ```

---

## 4. Pruebas web en cualquier navegador o dispositivo

El modo `flutter run -d chrome` depende del depurador DWDS y solo funciona en la ventana de Chrome que abre Flutter. Para probar en Edge, Firefox, celular o cualquier dispositivo usa siempre un build release:

```bash
flutter build web --release --no-web-resources-cdn
```

Despues sirve la carpeta `build/web` con un servidor estatico:

```bash
cd build/web
python -m http.server 8090
```

Abre `http://127.0.0.1:8090` en el navegador que quieras. Este build no usa DWDS, no registra service worker y sirve CanvasKit localmente.

Recomendaciones para desarrollo web:

- No refresques la pagina de `flutter run -d chrome` mientras compila; usa `R` para hot restart.
- No abras la URL de desarrollo en otro navegador ni en otra ventana; el modo debug se queda en blanco.
- En Windows, habilita el Modo para desarrolladores para que Flutter pueda crear los enlaces de los plugins.
- En Android, acepta el aviso de depuracion USB del telefono antes de ejecutar `flutter devices`.

---

## 5. Geolocalizacion

El mapa usa `geolocator` para el GPS real en Android, Windows, Linux y Web.

- **Android:** requiere los permisos `ACCESS_COARSE_LOCATION` y `ACCESS_FINE_LOCATION`, ya declarados en `android/app/src/main/AndroidManifest.xml`.
- **Web:** funciona en `localhost` o bajo HTTPS. En HTTP remoto el navegador bloquea la ubicacion y la app pasa a modo manual.
- **Windows:** requiere que el servicio de ubicacion del sistema este activo.
- **Linux:** usa Geoclue cuando esta disponible. Si no lo esta, la app continua en modo manual.

Si el usuario niega el permiso o el GPS no esta disponible, el mapa conserva el modo manual para elegir origen y destino.
