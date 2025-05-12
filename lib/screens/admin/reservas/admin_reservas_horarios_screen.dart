import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'agregar_reserva_screen.dart';

class AdminReservasHorariosScreen extends StatefulWidget {
  const AdminReservasHorariosScreen({Key? key}) : super(key: key);

  @override
  State<AdminReservasHorariosScreen> createState() =>
      _AdminReservasHorariosScreenState();
}

class _AdminReservasHorariosScreenState
    extends State<AdminReservasHorariosScreen> {
  DateTime _selectedDate = DateTime.now();
  late String _selectedDateStr;
  List<int> _reservedHours = [];

  @override
  void initState() {
    super.initState();
    _selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _loadReservedHours();
  }

  /// Consulta las reservas en Firestore para la fecha seleccionada y obtiene
  /// la lista de horas reservadas.
  Future<void> _loadReservedHours() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reservas')
        .where('fecha', isEqualTo: _selectedDateStr)
        .get();

    List<int> reserved = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      // Se asume que el campo 'horario' almacena un string del tipo "8:00" o "8:00 AM".
      String horarioStr = data['horario'] ?? "";
      if (horarioStr.isNotEmpty) {
        // Extraemos la parte numérica antes de los dos puntos.
        List<String> parts = horarioStr.split(":");
        if (parts.isNotEmpty) {
          int hour = int.tryParse(parts[0].trim()) ?? 0;
          reserved.add(hour);
        }
      }
    }
    setState(() {
      _reservedHours = reserved;
    });
  }

  /// Muestra un DatePicker para cambiar la fecha.
  Future<void> _selectDate() async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (newDate != null) {
      setState(() {
        _selectedDate = newDate;
        _selectedDateStr = DateFormat('yyyy-MM-dd').format(newDate);
      });
      _loadReservedHours();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos horas desde las 8 hasta las 22.
    List<int> hours = List.generate(15, (index) => index + 8);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservas - Horarios"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservedHours,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selector de fecha
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Fecha: $_selectedDateStr",
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
            // Grid de horas disponibles
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      4, // Muestra 4 columnas (ajústalo para PC/móvil)
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: hours.length,
                itemBuilder: (context, index) {
                  int hour = hours[index];
                  bool available = !_reservedHours.contains(hour);
                  String hourStr = "$hour:00";
                  return ElevatedButton(
                    onPressed: available
                        ? () {
                            // Navega a la pantalla de agregar reserva, pasando la fecha y hora seleccionada
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AgregarReservaScreen(
                                  fecha: _selectedDateStr,
                                  selectedHour: hourStr,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: available ? Colors.green : Colors.grey,
                    ),
                    child: Text(
                      available ? hourStr : "$hourStr (Ocupado)",
                      style: const TextStyle(color: Colors.white),
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
