import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/cancha.dart';

class CanchaProvider with ChangeNotifier {
  List<Cancha> _canchas = [];
  final Map<String, Map<DateTime, List<TimeOfDay>>> _horasReservadas = {};
  bool _isLoading = false;
  String _errorMessage = '';
  String? _currentSede; // 🚨 NUEVO: Para trackear la sede actual

  List<Cancha> get canchas => _canchas;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Map<DateTime, List<TimeOfDay>> horasReservadasPorCancha(String canchaId) {
    return _horasReservadas[canchaId] ?? {};
  }

  /// 🚨 NUEVO MÉTODO: Limpiar canchas
  void limpiarCanchas() {
    print('🧹 Limpiando canchas anteriores...');
    _canchas.clear();
    notifyListeners();
  }

  /// 🚨 MÉTODO CORREGIDO: La causa del problema estaba aquí
  Future<void> fetchCanchas(String sede) async {
    _isLoading = true;
    _errorMessage = '';

    // 🚨 SOLUCIÓN: Si cambió la sede, limpiar automáticamente
    if (_currentSede != null && _currentSede != sede) {
      print('🔄 Sede cambió de $_currentSede a $sede - Limpiando canchas...');
      _canchas.clear();
    }

    _currentSede = sede;
    notifyListeners();

    try {
      print('🔍 Buscando canchas para sede: $sede');

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('canchas')
          .where('sede', isEqualTo: sede)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _errorMessage = "No hay canchas registradas para esta sede.";
        print('⚠️ No se encontraron canchas para $sede');
      } else {
        // 🚨 SOLUCIÓN: Reemplazar completamente en lugar de combinar
        _canchas =
            querySnapshot.docs.map((doc) => Cancha.fromFirestore(doc)).toList();

        print('✅ Canchas cargadas para $sede: ${_canchas.length}');
        _canchas.forEach((cancha) {
          print('  - ${cancha.nombre} (${cancha.sede})');
        });
      }
    } catch (error) {
      _errorMessage = 'Error al cargar canchas: $error';
      print('❌ Error en fetchCanchas: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllCanchas() async {
    _isLoading = true;
    _errorMessage = '';
    _currentSede = null; // Reset sede tracking cuando se cargan todas
    notifyListeners();

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('canchas').get();

      if (querySnapshot.docs.isEmpty) {
        _errorMessage = "No hay canchas registradas.";
      }

      _canchas =
          querySnapshot.docs.map((doc) => Cancha.fromFirestore(doc)).toList();

      print('✅ Todas las canchas cargadas: ${_canchas.length}');
    } catch (error) {
      _errorMessage = 'Error al cargar todas las canchas: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHorasReservadas() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      QuerySnapshot reservasSnapshot =
          await FirebaseFirestore.instance.collection('reservas').get();
      _horasReservadas.clear();

      for (var doc in reservasSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final canchaId = data['cancha_id'] ?? '';
        final fecha = DateFormat('yyyy-MM-dd').parse(data['fecha']);
        final horaStrFull =
            data['horario'] as String; // Ej. "8:00 PM" o "20:00"
        final horaStr = horaStrFull.split(' ')[0]; // Ej. "8:00"
        final is12HourFormat =
            horaStrFull.contains(RegExp(r'(AM|PM)', caseSensitive: false));
        int hour = int.parse(horaStr.split(':')[0]);
        final minute = int.parse(horaStr.split(':')[1]);

        if (is12HourFormat) {
          final period = horaStrFull.toUpperCase().contains('PM') ? 'PM' : 'AM';
          if (period == 'PM' && hour != 12) {
            hour += 12; // Convertir a formato 24h
          } else if (period == 'AM' && hour == 12) {
            hour = 0; // 12 AM es 00:00
          }
        }

        final hora = TimeOfDay(hour: hour, minute: minute);

        _horasReservadas.putIfAbsent(canchaId, () => {});
        _horasReservadas[canchaId]!.putIfAbsent(fecha, () => []);
        if (!_horasReservadas[canchaId]![fecha]!.contains(hora)) {
          _horasReservadas[canchaId]![fecha]!.add(hora);
        }
      }
    } catch (error) {
      _errorMessage = 'Error al cargar horas reservadas: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🚨 NUEVO: Resetear completamente el provider
  void reset() {
    _canchas.clear();
    _horasReservadas.clear();
    _isLoading = false;
    _errorMessage = '';
    _currentSede = null;
    notifyListeners();
  }
}
