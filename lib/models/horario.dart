// lib/models/horario.dart (versión corregida)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Horario {
  final TimeOfDay hora;
  final bool disponible;

  Horario({
    required this.hora,
    this.disponible = true,
  });

  // Retorna la hora formateada, p. ej.: "8:00 PM"
  String get horaFormateada {
    final int hour12 = (hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod);
    final String minuteStr = hora.minute.toString().padLeft(2, '0');
    final String period = hora.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minuteStr $period';
  }

  // Normaliza el formato de la hora para comparaciones
  static String normalizarHora(String horaStr) {
    return horaStr.trim().toUpperCase();
  }

  /// Registra un horario ocupado en Firestore.
  /// Se almacena la fecha formateada con DateFormat() para consistencia.
  static Future<void> marcarHorarioOcupado({
    required DateTime fecha,
    required String canchaId,
    required String sede,
    required TimeOfDay hora,
  }) async {
    final String horaFormateada = Horario(hora: hora).horaFormateada;
    // Usamos DateFormat para la fecha
    final String fechaStr = DateFormat('yyyy-MM-dd').format(fecha);

    try {
      await FirebaseFirestore.instance.collection('reservas').add({
        'fecha': fechaStr,
        'cancha_id': canchaId,
        'sede': sede,
        'horario': horaFormateada, // Guardamos el formato original
        'estado': 'Pendiente',
        'created_at': Timestamp.now(),
      });
      print(
          '✅ Reserva guardada para $fechaStr a las $horaFormateada en $sede, cancha: $canchaId');
    } catch (e) {
      print('🔥 Error al marcar horario como ocupado: $e');
      throw Exception('🔥 Error al marcar horario como ocupado: $e');
    }
  }

  /// Genera los horarios disponibles para una fecha, cancha y sede determinada,
  /// considerando los horarios ocupados en Firestore.
  static Future<List<Horario>> generarHorarios({
    required DateTime fecha,
    required String canchaId,
    required String sede,
    QuerySnapshot?
        reservasSnapshot, // Permite pasar datos sin volver a consultar Firebase
  }) async {
    final List<Horario> horarios = [];
    const List<int> horasDisponibles = [
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23
    ];

    final String fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
    print(
        'Generando horarios para fecha: $fechaStr, cancha: $canchaId, sede: $sede');

    try {
      // Usa los datos ya obtenidos si están disponibles
      reservasSnapshot ??= await FirebaseFirestore.instance
          .collection('reservas')
          .where('fecha', isEqualTo: fechaStr)
          .where('cancha_id', isEqualTo: canchaId)
          .where('sede', isEqualTo: sede)
          .get();

      print('📊 ${reservasSnapshot.docs.length} reservas para $fechaStr');

      final List<String> horariosOcupados = reservasSnapshot.docs
          .map((doc) => normalizarHora(
              (doc.data() as Map<String, dynamic>)['horario'] ?? ''))
          .toList();

      final now = DateTime.now();
      bool esHoy = fechaStr == DateFormat('yyyy-MM-dd').format(now);

      for (var h in horasDisponibles) {
        final timeOfDay = TimeOfDay(hour: h, minute: 0);
        final String horaFormateada = Horario(hora: timeOfDay).horaFormateada;
        final bool ocupado =
            horariosOcupados.contains(normalizarHora(horaFormateada)) ||
                (esHoy && h <= now.hour);

        horarios.add(Horario(hora: timeOfDay, disponible: !ocupado));
      }

      return horarios;
    } catch (e) {
      print('🔥 Error al obtener horarios ocupados: $e');
      throw Exception('🔥 Error al obtener horarios ocupados: $e');
    }
  }
}
