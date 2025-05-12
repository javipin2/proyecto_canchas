import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Modelo básico para un Cliente.
class Client {
  final String id;
  final String nombre;
  final String telefono;
  Client({required this.id, required this.nombre, required this.telefono});
  factory Client.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      nombre: data['nombre'] ?? "",
      telefono: data['telefono'] ?? "",
    );
  }
}

class AgregarReservaScreen extends StatefulWidget {
  final String fecha;
  final String? selectedHour;
  const AgregarReservaScreen({Key? key, required this.fecha, this.selectedHour})
      : super(key: key);

  @override
  State<AgregarReservaScreen> createState() => _AgregarReservaScreenState();
}

class _AgregarReservaScreenState extends State<AgregarReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  String _clienteId = "";
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late String _selectedDateString;
  String _selectedHora = "";
  String _estado = "Pendiente";
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _tipoEventoController =
      TextEditingController(text: "Fútbol");
  String _sede = "Sede 1";

  @override
  void initState() {
    super.initState();
    _selectedDateString = widget.fecha;
    _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.fecha);
    if (widget.selectedHour != null) {
      _selectedHora = widget.selectedHour!;
    }
  }

  /// Obtiene la lista de clientes desde Firestore.
  Future<List<Client>> _fetchClientes() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('clientes').get();
    return snapshot.docs.map((doc) => Client.fromDoc(doc)).toList();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDateString = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitReserva() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHora.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selecciona una hora disponible")));
        return;
      }
      try {
        await FirebaseFirestore.instance.collection('reservas').add({
          'cliente_id': _clienteId,
          'nombre': _nombreController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'fecha': _selectedDateString,
          'horario': _selectedHora,
          'estado': _estado,
          'valor': double.tryParse(_valorController.text.trim()) ?? 0,
          'tipo_evento': _tipoEventoController.text.trim(),
          'sede': _sede,
          'created_at': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reserva registrada correctamente")));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al registrar reserva: $e")));
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _valorController.dispose();
    _tipoEventoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Esta pantalla muestra el formulario con la fecha y hora preseleccionadas.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Nueva Reserva"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                FutureBuilder<List<Client>>(
                  future: _fetchClientes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    List<Client> clientes = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Seleccionar Cliente",
                        border: OutlineInputBorder(),
                      ),
                      value: _clienteId.isNotEmpty ? _clienteId : null,
                      items: clientes.map((client) {
                        return DropdownMenuItem<String>(
                          value: client.id,
                          child: Text("${client.nombre} (${client.telefono})"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _clienteId = value ?? "";
                          Client selected =
                              clientes.firstWhere((c) => c.id == value);
                          _nombreController.text = selected.nombre;
                          _telefonoController.text = selected.telefono;
                        });
                      },
                      validator: (value) => (value == null || value.isEmpty)
                          ? "Selecciona un cliente"
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "Ingresa el nombre"
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: "Teléfono",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? "Ingresa el teléfono"
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Fecha: $_selectedDateString",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _selectDate,
                      child: const Text("Cambiar Fecha"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Muestra la hora preseleccionada (el admin la eligió previamente en el grid)
                TextFormField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: "Hora",
                    border: const OutlineInputBorder(),
                    hintText: _selectedHora.isNotEmpty
                        ? _selectedHora
                        : "Selecciona una hora desde el calendario",
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Estado",
                    border: OutlineInputBorder(),
                  ),
                  value: _estado,
                  items: const [
                    DropdownMenuItem(
                        value: "Pendiente", child: Text("Pendiente")),
                    DropdownMenuItem(
                        value: "Confirmado", child: Text("Confirmado")),
                    DropdownMenuItem(
                        value: "Cancelado", child: Text("Cancelado")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estado = value ?? "Pendiente";
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorController,
                  decoration: const InputDecoration(
                    labelText: "Valor",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tipoEventoController,
                  decoration: const InputDecoration(
                    labelText: "Tipo de Evento",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Sede",
                    border: OutlineInputBorder(),
                  ),
                  value: _sede,
                  items: const [
                    DropdownMenuItem(value: "Sede 1", child: Text("Sede 1")),
                    DropdownMenuItem(value: "Sede 2", child: Text("Sede 2")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sede = value ?? "Sede 1";
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitReserva,
                  child: const Text("Registrar Reserva"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
