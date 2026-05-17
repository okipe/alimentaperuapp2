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
  final Color primaryGreen = const Color(0xFF1A4D2E);
  final Color accentGreen = const Color(0xFF2E7D52);
  final Color bgColor = const Color(0xFFF4F7F5);

  final Set<String> _procesando = {};

  void _notificar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // LÓGICA MANTENIDA: Transacción de donación a inventario
  Future<void> _validarDonacion(DocumentSnapshot doc) async {
    final docId = doc.id;

    setState(() {
      _procesando.add(docId);
    });

    final data = doc.data() as Map<String, dynamic>;
    final String producto = data['producto'] ?? 'Otros';
    final double cantidadDonada = (data['cantidad'] ?? 0).toDouble();

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.update(doc.reference, {'estado': 'Completada'});

        final nuevoProductoRef = _firestore.collection('Productos').doc();
        transaction.set(nuevoProductoRef, {
          'nombre': producto,
          'categoria': data['categoria'] ?? 'General',
          'cantidad': cantidadDonada,
          'unidad': data['unidad'] ?? 'kg',
          'fecha_vencimiento': data['fecha_vencimiento'],
          'fecha_ingreso': FieldValue.serverTimestamp(),
          'estado': 'Disponible',
        });

        final movRef = _firestore.collection('Movimientos').doc();
        transaction.set(movRef, {
          'tipo': 'INGRESO',
          'producto': producto,
          'cantidad': cantidadDonada,
          'fecha': FieldValue.serverTimestamp(),
          'detalle': 'Donación - Lote individual',
          'unidad': data['unidad'] ?? 'kg',
        });
      });

      _notificar("✅ $producto ingresado al inventario", Colors.green);
    } catch (e) {
      debugPrint("Error en transacción: $e");
      _notificar("❌ Error al procesar el ingreso", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _procesando.remove(docId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // --- NUEVO DISEÑO DE HEADER (Basado en image_d11ddd.png) ---
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "SISTEMA DE DONACIONES",
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Validar Donaciones",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- LISTA CON LÓGICA DE STREAM ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('Donaciones')
                  .where('estado', isEqualTo: 'Pendiente')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Todo al día",
                          style: GoogleFonts.dmSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          "No hay donaciones pendientes.",
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    bool estaProcesando = _procesando.contains(docId);

                    String fechaStr = "Reciente";
                    if (data['fecha_registro'] != null) {
                      fechaStr = DateFormat(
                        'dd/MM/yy - HH:mm',
                      ).format((data['fecha_registro'] as Timestamp).toDate());
                    }

                    return _buildPremiumCard(
                      data,
                      docId,
                      estaProcesando,
                      () => _validarDonacion(docs[index]),
                      fechaStr,
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

  // --- WIDGET DE TARJETA MANTENIDO ---
  Widget _buildPremiumCard(
    Map<String, dynamic> data,
    String docId,
    bool isLoading,
    VoidCallback onValidate,
    String fechaStr,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.shopping_basket_rounded,
                    color: primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['producto']?.toUpperCase() ?? 'DONACIÓN',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: const Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Cantidad: ${data['cantidad']} ${data['unidad']}",
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: accentGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Registrado: $fechaStr",
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLoading ? Colors.grey[400] : primaryGreen,
                  elevation: isLoading ? 0 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading ? null : onValidate,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "INGRESAR AL INVENTARIO",
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
