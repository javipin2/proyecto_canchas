// lib/screens/admin/registrar_cancha_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrarCanchaScreen extends StatefulWidget {
  const RegistrarCanchaScreen({Key? key}) : super(key: key);

  @override
  State<RegistrarCanchaScreen> createState() => _RegistrarCanchaScreenState();
}

class _RegistrarCanchaScreenState extends State<RegistrarCanchaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _imagenController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _serviciosController = TextEditingController();
  bool _techada = false;
  String _sede = "";
  bool _isLoading = false;

  Future<void> _registrarCancha() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance.collection('canchas').add({
          'nombre': _nombreController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'imagen': _imagenController.text.trim(),
          'ubicacion': _ubicacionController.text.trim(),
          'precio': double.tryParse(_precioController.text.trim()) ?? 0,
          'techada': _techada,
          'sede': _sede,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cancha registrada correctamente")),
        );
        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al registrar cancha: $error")),
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
        title: const Text("Registrar Cancha"),
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
                // Imagen (ruta)
                TextFormField(
                  controller: _imagenController,
                  decoration: const InputDecoration(
                    labelText: "Ruta de Imagen",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Techada checkbox
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
                // Sede dropdown
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
                        onPressed: _registrarCancha,
                        child: const Text("Registrar Cancha"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
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
