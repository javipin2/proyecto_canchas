// lib/providers/cancha_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cancha.dart';

class CanchaProvider with ChangeNotifier {
  List<Cancha> _canchas = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Cancha> get canchas => _canchas;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// **Obtener canchas desde Firestore**
  Future<void> fetchCanchas(String sede) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('canchas')
          .where('sede', isEqualTo: sede)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _errorMessage = "No hay canchas registradas para esta sede.";
      }

      _canchas =
          querySnapshot.docs.map((doc) => Cancha.fromFirestore(doc)).toList();
    } catch (error) {
      _errorMessage = 'Error al cargar canchas: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
