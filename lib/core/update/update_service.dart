import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String apkUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const UpdateInfo({required this.latestVersion, required this.latestBuildNumber, required this.apkUrl, required this.releaseNotes, required this.forceUpdate});
}

/// Busca una versión nueva en las GitHub Releases del repo, descarga el APK y
/// abre el instalador de Android. Mismo flujo que CashflowIQ, pero sin backend.
///
/// Cómo publicar una versión (ver RELEASING.md):
///  - Tag `v<version>+<build>`, por ejemplo `v1.2.0+3` (el build debe ser mayor al instalado).
///  - Adjuntar el `.apk` como asset del release.
///  - El texto del release se muestra como novedades. Si incluye `#obligatoria`,
///    el diálogo no se puede cerrar sin actualizar.
class UpdateService {
  UpdateService._();

  static const _latestReleaseUrl = 'https://api.github.com/repos/alechuertasfranco/game_setter/releases/latest';
  static const _forceMarker = '#obligatoria';

  /// Devuelve null si ya está al día o si la consulta falla (nunca bloquea el arranque).
  static Future<UpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;

    try {
      final response = await http.get(Uri.parse(_latestReleaseUrl), headers: {'Accept': 'application/vnd.github+json'}).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = parseRelease(json);
      if (info == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      return info.latestBuildNumber > currentBuild ? info : null;
    } catch (_) {
      return null;
    }
  }

  /// Convierte la respuesta de GitHub en [UpdateInfo]. Público para poder testearlo.
  static UpdateInfo? parseRelease(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    final match = RegExp(r'^v?(\d+\.\d+\.\d+)\+(\d+)$').firstMatch(tag);
    if (match == null) return null;

    final assets = (json['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final apk = assets.where((a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.apk')).firstOrNull;
    final apkUrl = apk?['browser_download_url'] as String?;
    if (apkUrl == null) return null;

    final body = json['body'] as String? ?? '';

    return UpdateInfo(
      latestVersion: match.group(1)!,
      latestBuildNumber: int.parse(match.group(2)!),
      apkUrl: apkUrl,
      releaseNotes: body.replaceAll(_forceMarker, '').trim(),
      forceUpdate: body.contains(_forceMarker),
    );
  }

  /// Descarga el APK a una carpeta temporal, informando el progreso entre 0 y 1.
  static Future<String> downloadApk(String apkUrl, {void Function(double progress)? onProgress}) async {
    final client = http.Client();

    try {
      final response = await client.send(http.Request('GET', Uri.parse(apkUrl)));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/game_setter_update.apk');
      final sink = file.openWrite();

      final total = response.contentLength ?? 0;
      var received = 0;

      await response.stream.forEach((chunk) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) onProgress?.call(received / total);
      });

      await sink.close();
      return file.path;
    } finally {
      client.close();
    }
  }

  /// Abre el instalador de Android. La primera vez Android pide permitir
  /// "instalar apps desconocidas" para Game Setter.
  static Future<bool> installApk(String filePath) async {
    final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
    return result.type == ResultType.done;
  }
}
