import 'package:flutter/material.dart';

import 'update_service.dart';

/// Revisa si hay versión nueva y, si la hay, muestra el diálogo.
Future<void> checkForUpdateAndPrompt(BuildContext context) async {
  final info = await UpdateService.checkForUpdate();
  if (info == null || !context.mounted) return;
  await showUpdateDialog(context, info);
}

/// Muestra el aviso de actualización y maneja descarga → instalación.
/// Si la versión es obligatoria, el diálogo no se puede cerrar.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (_) => PopScope(canPop: !info.forceUpdate, child: _UpdateDialog(info: info)),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _progress = 0;
      _error = null;
    });

    try {
      final path = await UpdateService.downloadApk(widget.info.apkUrl, onProgress: (p) => mounted ? setState(() => _progress = p) : null);
      final opened = await UpdateService.installApk(path);
      if (!opened && mounted) {
        setState(() => _error = "No se pudo abrir el instalador. Revisa que Game Setter tenga permiso para instalar apps.");
      }
    } catch (_) {
      if (mounted) setState(() => _error = "No se pudo descargar la actualización. Intenta de nuevo.");
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final downloading = _progress != null;

    return AlertDialog(
      icon: const Icon(Icons.system_update, color: Colors.blueGrey, size: 32),
      title: Text('Nueva versión disponible', style: textTheme.headlineSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión ${widget.info.latestVersion}', style: textTheme.titleSmall?.copyWith(color: Colors.grey.shade700)),
            if (widget.info.releaseNotes.isNotEmpty) ...[const SizedBox(height: 12), Text(widget.info.releaseNotes, style: textTheme.bodyMedium)],
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: textTheme.bodyMedium?.copyWith(color: Colors.redAccent))],
            if (downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress! > 0 ? _progress : null),
              const SizedBox(height: 8),
              Text('${((_progress ?? 0) * 100).toStringAsFixed(0)}%', style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.info.forceUpdate && !downloading) TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Más tarde')),
        FilledButton(onPressed: downloading ? null : _startUpdate, child: Text(downloading ? 'Descargando…' : 'Actualizar ahora')),
      ],
    );
  }
}
