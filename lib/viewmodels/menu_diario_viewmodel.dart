import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuDiarioViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _platoPrincipal = 'Cargando menú...';
  String get platoPrincipal => _platoPrincipal;

  int _racionesDisponibles = 0;
  int get racionesDisponibles => _racionesDisponibles;

  String? _ultimoMenuId;

  MenuDiarioViewModel() {
    _escucharMenuEnTiempoReal();
  }

  void _escucharMenuEnTiempoReal() {
    _firestore
        .collection('Menues') // Sincronizado con el Administrador
        .orderBy('fecha', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              var lastDoc = snapshot.docs.first;
              _ultimoMenuId = lastDoc.id;
              var data = lastDoc.data();

              _platoPrincipal = data['plato'] ?? 'Menú no disponible';

              var rac = data['raciones'] ?? 0;
              _racionesDisponibles = rac is double ? rac.toInt() : (rac as int);
            } else {
              _platoPrincipal = 'No hay platos registrados hoy';
              _racionesDisponibles = 0;
              _ultimoMenuId = null;
            }
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> reservarRacion() async {
    if (_ultimoMenuId == null || _racionesDisponibles <= 0) return false;
    try {
      await _firestore.collection('Menues').doc(_ultimoMenuId).update({
        'raciones': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
