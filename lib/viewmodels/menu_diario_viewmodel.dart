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

  // --- NUEVA LÓGICA: ESCUCHA EN TIEMPO REAL ---
  void _escucharMenuEnTiempoReal() {
    _firestore
        .collection('Menus')
        .orderBy(
          'fecha_registro',
          descending: true,
        ) // Trae el más reciente primero
        .limit(1) // Solo necesitamos 1, ahorra datos
        .snapshots() // Se queda escuchando cambios 24/7
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              var lastDoc = snapshot.docs.first;
              _ultimoMenuId = lastDoc.id;
              var data = lastDoc.data() as Map<String, dynamic>;

              // Soporta si en Firestore lo escriben como 'Plato' o 'plato'
              _platoPrincipal =
                  data['Plato'] ?? data['plato'] ?? 'Menú no disponible';
              _racionesDisponibles = (data['raciones'] ?? 0) as int;
            } else {
              _platoPrincipal = 'No hay platos registrados hoy';
              _racionesDisponibles = 0;
              _ultimoMenuId = null;
            }

            _isLoading = false;
            notifyListeners(); // Actualiza la pantalla automáticamente
          },
          onError: (error) {
            _platoPrincipal = 'Error al conectar con el menú';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // FUNCIÓN PARA DESCONTAR RACIONES
  Future<bool> reservarRacion() async {
    if (_ultimoMenuId == null || _racionesDisponibles <= 0) return false;

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference menuRef = _firestore
            .collection('Menus')
            .doc(_ultimoMenuId);
        DocumentSnapshot snapshot = await transaction.get(menuRef);

        if (snapshot.exists) {
          int currentRaciones =
              (snapshot.data() as Map<String, dynamic>)['raciones'] ?? 0;
          if (currentRaciones > 0) {
            transaction.update(menuRef, {'raciones': currentRaciones - 1});
          } else {
            throw Exception("No quedan raciones");
          }
        }
      });
      // No necesitamos restar manualmente _racionesDisponibles-- porque
      // el .snapshots() de arriba detectará el cambio y lo actualizará solo.
      return true;
    } catch (e) {
      return false;
    }
  }
}
