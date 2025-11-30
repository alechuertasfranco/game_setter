Aquí tienes un **README.md profesional y claro** para tu proyecto *Game Setter*, basado en todo lo que hemos construido: Flutter, SQLite, gestión de jugadores, deportes y posiciones, e importación desde contactos.

Si quieres puedo adaptarlo a un estilo más técnico, más comercial o incluso en español/inglés mixto como te guste más.

---

# 🏐⚽🏀 Game Setter

**Gestor de jugadores, deportes y posiciones para partidos rápidos**

Game Setter es una aplicación Flutter diseñada para organizar jugadores de distintos deportes, asignar posiciones y gestionar equipos de forma rápida y sencilla.
Incluye integración con contactos del dispositivo, base de datos local SQLite y una arquitectura modular por features.

---

## ✨ Características principales

### 👤 Gestión de jugadores

* Crear, editar y eliminar jugadores.
* Importar información directamente desde los **contactos del teléfono** (nombre + número).
* Asociar opcionalmente un **deporte** y una **posición** al jugador.

### 🏅 Gestión deportiva

* Base de datos con deportes preconfigurados:

  * **Vóley**
  * **Fútbol**
  * **Básquet**
* Cada deporte incluye un conjunto de **posiciones predefinidas**, por ejemplo:

  * Vóley → Armador, Opuesto, Punta, Central, Líbero
  * Fútbol → Arquero, Defensa, Mediocampista, Delantero
  * Básquet → Base, Escolta, Alero, Ala-Pívot, Pívot

### 💾 Persistencia local (SQLite)

* Base de datos integrada usando **sqflite**.
* Migraciones listas para futuras expansiones (partidos, pagos, historial, etc.).

### 📱 Arquitectura limpia por features

* `features/players`
* `features/sports`
* `features/positions`
* `core/db` para SQLite
* Repositorios separados por dominio

---

## 📂 Estructura del proyecto

```
lib/
 ├─ core/
 │   └─ db/
 │       └─ database_service.dart
 ├─ features/
 │   ├─ players/
 │   │   ├─ data/
 │   │   │   └─ player_repository.dart
 │   │   ├─ domain/
 │   │   │   └─ entities/
 │   │   │       └─ player.dart
 │   │   └─ presentation/
 │   │       ├─ pages/
 │   │       │   ├─ players_page.dart
 │   │       │   └─ add_player_page.dart
 │   │       └─ widgets/
 │   │           └─ player_card.dart
 │   ├─ sports/
 │   │   └─ domain/entities/sport.dart
 │   └─ positions/
 │       └─ domain/entities/position.dart
```

---

## 🗄️ Base de datos

La base de datos `game_setter.db` se crea automáticamente con:

### Tablas

* `sports`
* `players`
* `positions`
* `player_sports` (asociación)

### Datos iniciales

Los deportes y sus posiciones están precargados.

---

## 🚀 Cómo iniciar el proyecto

### 1. Instalar dependencias

```sh
flutter pub get
```

### 2. Ejecutar en un dispositivo/emulador

```sh
flutter run
```

### 3. Si usas Android:

Asegúrate de haber configurado los permisos de contactos en el `AndroidManifest.xml`.

---

## 🔧 Requisitos

* Flutter 3.22+
* Herramientas de compilación para Android y/o iOS
* Permiso de lectura de contactos (Android/iOS)

---

## 📚 TODO / Próximas mejoras

* Crear equipos automáticamente según deporte.
* Historial de partidos y asistencia.
* Nivel de habilidad por jugador.
* Integración cloud (opcional).
* Tema oscuro personalizado.

---

## 📄 Licencia

MIT License — libre para usar y modificar.

---

Si quieres, puedo generar también:
✅ Logo para el proyecto
✅ Badges (Flutter, Sqflite, Android, etc.)
✅ Screenshots fake/mockups
✅ Versión más corta o más larga del README
Solo dime y lo hago.
