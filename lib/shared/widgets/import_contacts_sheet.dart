import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Muestra un Bottom Sheet con los contactos y devuelve
/// el contacto seleccionado como Map {'name': nombre, 'phone': telefono}.
Future<Map<String, String?>?> showImportContactsSheet(BuildContext context) async {
  // Pedir permiso
  final status = await Permission.contacts.request();
  if (!status.isGranted) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso para acceder a contactos denegado')));
    return null;
  }

  // Cargar contactos
  List<Contact> contacts = [];
  bool isLoading = true;

  try {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso para acceder a contactos denegado')));
      return null;
    }

    contacts = await FlutterContacts.getContacts(withProperties: true);
  } catch (e) {
    contacts = [];
  }
  isLoading = false;

  if (!context.mounted) return null;

  // Lista filtrada inicial
  List<Contact> filteredContacts = List.from(contacts);

  // Mostrar Bottom Sheet
  return await showModalBottomSheet<Map<String, String?>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, modalSetState) {
          void filterContacts(String query) {
            final lowerQuery = query.toLowerCase();
            modalSetState(() {
              filteredContacts = contacts.where((c) => c.displayName.toLowerCase().contains(lowerQuery)).toList();
            });
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Selecciona un contacto", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Input de búsqueda mejorado
                  TextField(
                    onChanged: filterContacts,
                    decoration: InputDecoration(
                      hintText: 'Buscar contacto...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredContacts.isEmpty
                        ? const Center(child: Text("No hay contactos disponibles"))
                        : ListView.builder(
                            itemCount: filteredContacts.length,
                            itemBuilder: (context, i) {
                              final c = filteredContacts[i];
                              final phone = c.phones.isNotEmpty ? c.phones.first.number : null;

                              return ListTile(
                                title: Text(c.displayName),
                                subtitle: phone != null ? Text(phone) : null,
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx, {'name': c.displayName, 'phone': phone});
                                  },
                                  child: const Text("Seleccionar"),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cerrar")),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
