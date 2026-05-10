import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonacionViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> categorias = [];
  List<Map<String, dynamic>> productosFiltrados = [];

  DonacionViewModel() {
    cargarCategoriasDesdeStock();
  }

  // Carga las categorías que existen actualmente en tu inventario
  Future<void> cargarCategoriasDesdeStock() async {
    try {
      var snapshot = await _firestore.collection('Inventario').get();
      var cats = snapshot.docs
          .map((doc) => doc['categoria'].toString())
          .toSet()
          .toList();
      categorias = cats;
      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando categorías: $e");
    }
  }

  // Filtra los productos de la categoría seleccionada para evitar errores de escritura
  Future<void> cargarProductosPorCategoria(String categoria) async {
    _isLoading = true;
    notifyListeners();
    try {
      var snapshot = await _firestore
          .collection('Inventario')
          .where('categoria', isEqualTo: categoria)
          .get();

      productosFiltrados = snapshot.docs
          .map((doc) => {'id': doc.id, 'nombre': doc['nombre']})
          .toList();
    } catch (e) {
      debugPrint("Error filtrando productos: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // Procesa la donación: Suma al stock o registra ingreso de dinero
  Future<bool> registrarDonacion({
    required bool esDinero,
    double? monto,
    String? productoId,
    String? productoNombre,
    int? cantidadDonada,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String uid = _auth.currentUser?.uid ?? "anonimo";

      await _firestore.runTransaction((transaction) async {
        // 1. Registro histórico del gesto de donación
        DocumentReference donacionRef = _firestore
            .collection('Donaciones')
            .doc();
        transaction.set(donacionRef, {
          'donanteID': uid,
          'tipo': esDinero ? 'Dinero' : 'Producto',
          'monto': monto ?? 0.0,
          'producto': productoNombre ?? 'N/A',
          'cantidad': cantidadDonada ?? 0,
          'fecha': FieldValue.serverTimestamp(),
        });

        if (esDinero) {
          // 2. Sumar a la cuenta de Ingresos
          DocumentReference ingresoRef = _firestore
              .collection('Ingresos')
              .doc();
          transaction.set(ingresoRef, {
            'origen': 'Donación Voluntaria',
            'monto': monto,
            'fecha': FieldValue.serverTimestamp(),
          });
        } else {
          // 3. Sumar al stock físico en Inventario
          DocumentReference invRef = _firestore
              .collection('Inventario')
              .doc(productoId);
          DocumentSnapshot invSnap = await transaction.get(invRef);

          if (invSnap.exists) {
            int stockActual =
                (invSnap.data() as Map<String, dynamic>)['cantidad'] ?? 0;
            transaction.update(invRef, {
              'cantidad': stockActual + cantidadDonada!,
            });
          }
        }
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error en proceso de donación: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
