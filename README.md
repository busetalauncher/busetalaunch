# Buseta Launcher (radio Android, liquid glass)

## Obtener el APK sin instalar nada (GitHub)
1. En github.com crea un repositorio nuevo (tuyo) y sube TODO el contenido de esta carpeta
   (incluida la carpeta oculta `.github`).
2. Entra a la pestaña **Actions** -> "Compilar APK". Se ejecuta solo al subir; espera ~5-8 min.
   Si no arranca: "Run workflow".
3. Abre la ejecución terminada -> abajo en **Artifacts** descarga `BusetaLauncher-apk` (zip con `app-release.apk`).

## Instalar en la radio
1. Pasa el APK por USB/memoria e instálalo (permite "orígenes desconocidos").
2. Abre la app, acepta el permiso de **ubicación**.
3. Pulsa el botón Home de la radio y elige **Buseta Launcher -> Siempre**.

## Qué hace cada botón
Waze / mapa / "Abrir Waze": abre Waze. Casa y Trabajo: navegan a esos favoritos guardados en Waze.
YouTube: abre youtube.com en **Brave**. Spotify: abre la app de Spotify.
Círculo: lista de todas las apps. Luna: modo noche. Tune: sonido. Engranaje: ajustes. Bluetooth: ajustes de Bluetooth.
Tocar al muñeco repite el saludo. Cambia nombre/ciudad en `lib/main.dart` (constantes del inicio).
