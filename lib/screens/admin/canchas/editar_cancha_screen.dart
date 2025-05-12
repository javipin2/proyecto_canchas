// lib/screens/admin/editar_cancha_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarCanchaScreen extends StatefulWidget {
  final String canchaId;
  final Map<String, dynamic> canchaData;
  const EditarCanchaScreen({
    Key? key,
    required this.canchaId,
    required this.canchaData,
  }) : super(key: key);

  @override
  State<EditarCanchaScreen> createState() => _EditarCanchaScreenState();
}

class _EditarCanchaScreenState extends State<EditarCanchaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _imagenController;
  late TextEditingController _ubicacionController;
  late TextEditingController _precioController;
  late TextEditingController _serviciosController;
  bool _techada = false;
  String _sede = "";

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.canchaData['nombre'] ?? "");
    _descripcionController =
        TextEditingController(text: widget.canchaData['descripcion'] ?? "");
    _imagenController =
        TextEditingController(text: widget.canchaData['imagen'] ?? "");
    _ubicacionController =
        TextEditingController(text: widget.canchaData['ubicacion'] ?? "");
    _precioController = TextEditingController(
        text: widget.canchaData['precio']?.toString() ?? "");
    _serviciosController = TextEditingController(
        text: widget.canchaData['servicios']?.toString() ?? "");
    _techada = widget.canchaData['techada'] ?? false;
    _sede = widget.canchaData['sede'] ?? "";
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance
            .collection('canchas')
            .doc(widget.canchaId)
            .update({
          'nombre': _nombreController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'imagen': _imagenController.text.trim(),
          'ubicacion': _ubicacionController.text.trim(),
          'precio': double.tryParse(_precioController.text.trim()) ?? 0,
          'servicios': _serviciosController.text.trim(),
          'techada': _techada,
          'sede': _sede,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cancha actualizada correctamente")),
        );
        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar cancha: $error")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _imagenController.dispose();
    _ubicacionController.dispose();
    _precioController.dispose();
    _serviciosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Cancha"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "Ingrese el nombre"
                      : null,
                ),
                const SizedBox(height: 16),
                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: "Descripción",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Imagen
                TextFormField(
                  controller: _imagenController,
                  decoration: const InputDecoration(
                    labelText: "Ruta de Imagen",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Techada (checkbox)
                CheckboxListTile(
                  title: const Text("¿Es techada?"),
                  value: _techada,
                  onChanged: (value) {
                    setState(() {
                      _techada = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Ubicación
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(
                    labelText: "Ubicación",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Precio
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(
                    labelText: "Precio",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Servicios
                TextFormField(
                  controller: _serviciosController,
                  decoration: const InputDecoration(
                    labelText: "Servicios",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Sede (must select one of the two opciones)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Sede",
                    border: OutlineInputBorder(),
                  ),
                  value: _sede.isNotEmpty ? _sede : null,
                  items: const [
                    DropdownMenuItem(value: "Sede 1", child: Text("Sede 1")),
                    DropdownMenuItem(value: "Sede 2", child: Text("Sede 2")),
                  ],
                  validator: (value) => value == null || value.isEmpty
                      ? "Seleccione la sede"
                      : null,
                  onChanged: (value) {
                    setState(() {
                      _sede = value ?? "";
                    });
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _guardarCambios,
                        child: const Text("Guardar Cambios"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
