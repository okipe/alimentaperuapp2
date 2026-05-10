import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class GestionDonacionesView extends StatefulWidget {
  const GestionDonacionesView({super.key});

  @override
  State<GestionDonacionesView> createState() => _GestionDonacionesViewState();
}

class _GestionDonacionesViewState extends State<GestionDonacionesView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filtroUsuario = "";

  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  Future<void> _validarDonacion(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final String producto = data['producto'] ?? 'Otros';
    final double cantidadDonada = (data['cantidad'] ?? 0).toDouble();

    try {
      await _firestore.runTransaction((transaction) async {
        // 🔥 Actualizamos a 'Completada' (C mayúscula)
        transaction.update(doc.reference, {'estado': 'Completada'});

        final productosQuery = await _firestore
            .collection('Productos')
            .where('nombre', isEqualTo: producto)
            .limit(1)
            .get();

        if (productosQuery.docs.isNotEmpty) {
          final docProducto = productosQuery.docs.first;
          double stockActual = (docProducto['cantidad'] as num).toDouble();
          transaction.update(docProducto.reference, {
            'cantidad': stockActual + cantidadDonada,
            'ultima_actualizacion': FieldValue.serverTimestamp(),
          });
        } else {
          final nuevoProductoRef = _firestore.collection('Productos').doc();
          transaction.set(nuevoProductoRef, {
            'nombre': producto,
            'categoria': data['categoria'],
            'cantidad': cantidadDonada,
            'unidad': data['unidad'],
            'fecha_ingreso': FieldValue.serverTimestamp(),
            'estado': 'Disponible',
          });
        }

        final movRef = _firestore.collection('Movimientos').doc();
        transaction.set(movRef, {
          'tipo': 'INGRESO_DONACION',
          'producto': producto,
          'cantidad': cantidadDonada,
          'fecha': FieldValue.serverTimestamp(),
          'detalle': 'Validación donación',
        });
      });

      _notificar("✅ Donación validada e inventario actualizado", Colors.green);
    } catch (e) {
      _notificar("❌ Error al procesar: $e", Colors.red);
    }
  }

  void _notificar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "GESTIÓN DE DONACIONES",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: darkGreen,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: darkGreen,
            child: TextField(
              onChanged: (v) => setState(() => _filtroUsuario = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar...",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 🔥 MODO PRO: Exactamente igual que en el guardado ('Donaciones' y 'Pendiente')
              stream: _firestore
                  .collection('Donaciones')
                  .where('estado', isEqualTo: 'Pendiente')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (_filtroUsuario.isNotEmpty)
                  docs = docs
                      .where(
                        (d) => d['producto'].toString().toLowerCase().contains(
                          _filtroUsuario.toLowerCase(),
                        ),
                      )
                      .toList();

                if (docs.isEmpty)
                  return Center(
                    child: Text(
                      "No hay donaciones pendientes",
                      style: GoogleFonts.dmSans(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: bgColor,
                          child: Icon(
                            Icons.volunteer_activism,
                            color: accentGreen,
                          ),
                        ),
                        title: Text(
                          data['producto'] ?? 'Donación',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        subtitle: Text(
                          "Cantidad: ${data['cantidad']} ${data['unidad']}",
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGreen,
                          ),
                          onPressed: () => _validarDonacion(docs[index]),
                          child: const Text(
                            "VALIDAR",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
