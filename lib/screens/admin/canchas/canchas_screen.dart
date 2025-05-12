// lib/screens/admin/canchas_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editar_cancha_screen.dart';
import 'registrar_cancha_screen.dart';

class CanchasScreen extends StatefulWidget {
  const CanchasScreen({Key? key}) : super(key: key);

  @override
  State<CanchasScreen> createState() => _CanchasScreenState();
}

class _CanchasScreenState extends State<CanchasScreen> {
  // Variable para el filtro; si está vacío, se muestran todas las sedes.
  String _selectedSede = "";

  // Lista fija de sedes para el filtro
  final List<String> sedes = ["Sede 1", "Sede 2"];

  // Construye la consulta de Firestore de acuerdo al filtro
  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('canchas');
    if (_selectedSede.isNotEmpty) {
      query = query.where('sede', isEqualTo: _selectedSede);
    }
    return query;
  }

  // Función para eliminar una cancha con confirmación
  Future<void> _eliminarCancha(String canchaId, BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Deseas eliminar esta cancha?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('canchas')
            .doc(canchaId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cancha eliminada correctamente")),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar: $error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Query query = _buildQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Canchas"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Título
            const Text(
              "Canchas",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Botón para registrar una nueva cancha
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrarCanchaScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Registrar Nueva Cancha"),
            ),
            const SizedBox(height: 16),
            // Filtro por sede
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Filtrar por Sede",
                      border: OutlineInputBorder(),
                    ),
                    // Si no hay filtro, el valor es nulo para mostrar "Todas las sedes"
                    value: _selectedSede.isNotEmpty ? _selectedSede : null,
                    items: [
                      const DropdownMenuItem(
                        value: "",
                        child: Text("Todas las sedes"),
                      ),
                      ...sedes.map((sede) => DropdownMenuItem(
                            value: sede,
                            child: Text(sede),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSede = value ?? "";
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Se reconstruye la consulta con el filtro
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Filtrar"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tabla que muestra las canchas
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final canchaDocs = snapshot.data!.docs;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("ID")),
                        DataColumn(label: Text("Nombre")),
                        DataColumn(label: Text("Sede")),
                        DataColumn(label: Text("Descripción")),
                        DataColumn(label: Text("Precio")),
                        DataColumn(label: Text("Acciones")),
                      ],
                      rows: canchaDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(doc.id)),
                          DataCell(Text(data['nombre'] ?? "")),
                          DataCell(Text(data['sede'] ?? "N/A")),
                          DataCell(Text(data['descripcion'] ?? "")),
                          DataCell(Text(data['precio']?.toString() ?? "")),
                          DataCell(
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditarCanchaScreen(
                                          canchaId: doc.id,
                                          canchaData: data,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      minimumSize: const Size(60, 30)),
                                  child: const Text(
                                    "Editar",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    _eliminarCancha(doc.id, context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      minimumSize: const Size(60, 30)),
                                  child: const Text(
                                    "Eliminar",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
