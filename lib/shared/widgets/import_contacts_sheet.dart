import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Muestra un Bottom Sheet con los contactos y devuelve
/// los contactos seleccionados como List<Map {'name': nombre, 'phone': telefono}>.
Future<List<Map<String, String?>>?> showImportContactsSheet(BuildContext context) async {
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
  Set<Contact> selectedContacts = {};

  return await showModalBottomSheet<List<Map<String, String?>>>(
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

          void toggleSelection(Contact contact) {
            modalSetState(() {
              if (selectedContacts.contains(contact)) {
                selectedContacts.remove(contact);
              } else {
                selectedContacts.add(contact);
              }
            });
          }

          void handleAdd() {
            final result = selectedContacts.map((c) => {'name': c.displayName, 'phone': c.phones.isNotEmpty ? c.phones.first.number : null}).toList();
            Navigator.pop(ctx, result);
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Selecciona contactos", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Buscador
                  TextField(
                    onChanged: filterContacts,
                    decoration: InputDecoration(
                      hintText: 'Buscar contacto...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista de contactos
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
                              final isSelected = selectedContacts.contains(c);

                              return ListTile(
                                title: Text(c.displayName),
                                subtitle: phone != null ? Text(phone) : null,
                                trailing: IconButton(
                                  icon: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.green : Colors.grey),
                                  onPressed: () => toggleSelection(c),
                                ),
                                onTap: () => toggleSelection(c),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),

                  // Botones de acción
                  Row(
                    spacing: 12,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200),
                        child: const Text("Cancelar", style: TextStyle(color: Colors.blueGrey)),
                      ),
                      ElevatedButton(onPressed: selectedContacts.isEmpty ? null : handleAdd, child: const Text("Agregar")),
                    ],
                  ),
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
