// lib/providers/sede_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SedeProvider with ChangeNotifier {
  String _sede = 'Sede 1'; // Valor por defecto

  String get sede => _sede;

  /// **Obtener sede almacenada en Firestore**
  Future<void> cargarSede() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('sedeActual')
          .get();
      if (doc.exists) {
        _sede = doc['sede'] ?? 'Sede 1';
        notifyListeners();
      }
    } catch (error) {
      print('🔥 Error al cargar sede: $error');
    }
  }

  /// **Actualizar sede y esperar confirmación antes de notificar cambios**
  Future<void> setSede(String nuevaSede) async {
    try {
      await FirebaseFirestore.instance
          .collection('config')
          .doc('sedeActual')
          .set({'sede': nuevaSede});

      // 🔄 Aseguramos que la sede realmente se ha cambiado en Firestore antes de actualizar el estado
      _sede = nuevaSede;
      notifyListeners();
    } catch (error) {
      print('🔥 Error al actualizar sede en Firestore: $error');
    }
  }
}
