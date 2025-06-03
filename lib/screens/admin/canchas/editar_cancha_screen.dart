import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/cancha.dart'; // Importar el modelo Cancha

class EditarCanchaScreen extends StatefulWidget {
  final String canchaId;
  final Cancha cancha; // Usar el modelo Cancha en lugar de Map<String, dynamic>
  const EditarCanchaScreen({
    Key? key,
    required this.canchaId,
    required this.cancha,
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
  String? _selectedDay;
  late Map<String, Map<String, double>> _preciosPorHorario;
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];

  // Horarios disponibles (5:00 AM a 11:00 PM, según Horario.dart)
  final List<String> _horarios = List.generate(19, (index) => '${5 + index}:00')
      .where((h) => int.parse(h.split(':')[0]) <= 23)
      .toList();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cancha.nombre);
    _descripcionController =
        TextEditingController(text: widget.cancha.descripcion);
    _imagenController = TextEditingController(text: widget.cancha.imagen);
    _ubicacionController = TextEditingController(text: widget.cancha.ubicacion);
    _precioController =
        TextEditingController(text: widget.cancha.precio.toString());
    _serviciosController =
        TextEditingController(); // Servicios no está en el modelo
    _techada = widget.cancha.techada;
    _sede = widget.cancha.sede;

    // Inicializar preciosPorHorario desde el modelo Cancha
    _preciosPorHorario = Map.from(widget.cancha.preciosPorHorario);
    for (var day in _daysOfWeek) {
      if (!_preciosPorHorario.containsKey(day)) {
        _preciosPorHorario[day] = {};
        for (var hora in _horarios) {
          _preciosPorHorario[day]![hora] = widget.cancha.precio;
        }
      }
    }
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
          'preciosPorHorario': _preciosPorHorario,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cancha actualizada correctamente")),
          );
        }
        Navigator.pop(context);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al actualizar cancha: $error")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
        title: Text(
          "Editar Cancha",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: "Descripción",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imagenController,
                  decoration: const InputDecoration(
                    labelText: "Ruta de Imagen",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(
                    labelText: "Ubicación",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(
                    labelText: "Precio por defecto",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serviciosController,
                  decoration: const InputDecoration(
                    labelText: "Servicios",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Día para editar precios",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDay,
                  hint: const Text("Selecciona un día"),
                  items: _daysOfWeek.map((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day[0].toUpperCase() + day.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedDay != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Precios para $_selectedDay",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._horarios.map((hora) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      hora,
                                      style: GoogleFonts.montserrat(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: _preciosPorHorario[
                                                  _selectedDay]![hora]
                                              ?.toString() ??
                                          "0",
                                      decoration: InputDecoration(
                                        labelText: "Precio ($hora)",
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          _preciosPorHorario[_selectedDay]![
                                                  hora] =
                                              double.tryParse(value) ?? 0.0;
                                        });
                                      },
                                      validator: (value) {
                                        final parsed =
                                            double.tryParse(value ?? '');
                                        if (parsed == null || parsed < 0) {
                                          return "Ingrese un precio válido";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
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
