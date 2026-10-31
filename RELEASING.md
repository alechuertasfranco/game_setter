# Publicar una versión nueva

La app revisa al abrirse la última release de GitHub
(`alechuertasfranco/game_setter`). Si su build es mayor al instalado, muestra
"Nueva versión disponible", descarga el APK y abre el instalador de Android.

## Pasos

1. Subir la versión en `pubspec.yaml` (el número después del `+` **siempre** debe aumentar):

   ```yaml
   version: 1.2.0+3
   ```

2. Si cambiaste la base de datos, subir `version:` en `lib/core/db/database_service.dart`
   y agregar la migración en `_upgradeDB` (nunca borrar datos). Se ejecuta sola la
   primera vez que el usuario abre la versión nueva.

3. Compilar en **esta misma PC** (el APK se firma con la llave local; si cambia,
   Android no deja instalar encima):

   ```bash
   flutter build apk --release
   ```

4. Publicar la release con el tag `v<version>+<build>` y el APK adjunto:

   ```bash
   gh release create v1.2.0+3 build/app/outputs/flutter-apk/app-release.apk#game_setter-1.2.0.apk \
     --title "Game Setter 1.2.0" --notes "- Qué cambió"
   ```

   Si la actualización debe ser obligatoria, incluir `#obligatoria` en las notas
   (no se muestra al usuario; el diálogo no se podrá cerrar).

## Nota

La versión 1.0.0 no tenía actualizador: la 1.1.0 se instala a mano una vez.
Desde ahí en adelante las versiones llegan solas.
