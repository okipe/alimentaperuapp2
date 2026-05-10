import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Función para descontar stock
  Future<void> descontarInsumo(
    String nombreInsumo,
    double cantidadARestar,
  ) async {
    try {
      // 1. Buscamos el producto por nombre
      final query = await _db
          .collection('Productos')
          .where('nombre', isEqualTo: nombreInsumo)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        double stockActual = (doc['cantidad'] as num).toDouble();

        // 2. Actualizamos el stock en la nube
        await _db.collection('Productos').doc(doc.id).update({
          'cantidad': stockActual - cantidadARestar,
        });
      }
    } catch (e) {
      print("Error al descontar stock: $e");
    }
  }
}
