import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EstadoPagosViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // --- SOLUCIÓN: Variables para guardar los Streams en memoria ---
  String? _lastUid;
  Stream<DocumentSnapshot>? _usuarioStream;
  Stream<QuerySnapshot>? _pagosStream;
  Stream<QuerySnapshot>? _recargasStream;

  // Verifica que siempre leamos los datos del usuario correcto
  void _verificarUsuario() {
    final uid = _auth.currentUser?.uid;
    if (_lastUid != uid) {
      _usuarioStream = null;
      _pagosStream = null;
      _recargasStream = null;
      _lastUid = uid;
    }
  }

  // 1. Cargar el saldo del usuario (sin reiniciar conexiones)
  Stream<DocumentSnapshot> getStreamUsuario() {
    _verificarUsuario();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    _usuarioStream ??= _firestore.collection('usuarios').doc(uid).snapshots();
    return _usuarioStream!;
  }

  // 2. Cargar historial de pagos (estable y en caché)
  Stream<QuerySnapshot> getHistorialPagos() {
    _verificarUsuario();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    _pagosStream ??= _firestore
        .collection('Pagos')
        .where('comensalID', isEqualTo: uid)
        // .orderBy('fecha', descending: true) // Actívalo cuando crees el Índice
        .snapshots();
    return _pagosStream!;
  }

  // 3. Cargar historial de recargas (estable y en caché)
  Stream<QuerySnapshot> getHistorialRecargas() {
    _verificarUsuario();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    _recargasStream ??= _firestore
        .collection('Recargas')
        .where('comensalID', isEqualTo: uid)
        // .orderBy('fecha', descending: true) // Actívalo cuando crees el Índice
        .snapshots();
    return _recargasStream!;
  }

  Future<bool> pagarCuotaSemanal(double montoCuota, String semana) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final userRef = _firestore.collection('usuarios').doc(uid);
      final pagoRef = _firestore.collection('Pagos').doc();

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        double saldo = (userSnapshot.get('saldo') ?? 0).toDouble();

        if (saldo >= montoCuota) {
          transaction.update(userRef, {'saldo': saldo - montoCuota});
          transaction.set(pagoRef, {
            'comensalID': uid,
            'monto': montoCuota,
            'semana': semana,
            'estado': 'Completado',
            'fecha': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception("Saldo insuficiente.");
        }
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> solicitarRecarga(
    double monto,
    String metodoPago,
    String nroOperacion,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('usuarios')
          .doc(uid)
          .get();
      String nombre = userDoc.get('nombre') ?? '';
      String apellido = userDoc.get('apellido') ?? '';
      String nombreCompleto = "$nombre $apellido".trim();

      await _firestore.collection('Recargas').add({
        'comensalID': uid,
        'nombre': nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
        'monto': monto,
        'metodo_pago': metodoPago,
        'nro_operacion': nroOperacion,
        'estado': 'pendiente',
        'fecha': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Error al solicitar recarga: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
