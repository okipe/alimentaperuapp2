import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class GestionSaldosView extends StatelessWidget {
  const GestionSaldosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F7F5,
      ), // Fondo ligeramente gris para resaltar tarjetas
      body: Column(
        children: [
          // --- CABECERA PROFESIONAL ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        "APROBACIÓN DE SALDOS",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Validación de recargas pendientes",
                  style: GoogleFonts.urbanist(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // --- LISTA EN TIEMPO REAL ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Recargas')
                  .where('estado', isEqualTo: 'pendiente')
                  // .orderBy('fecha', descending: false) // Opcional si activas el índice
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  );
                }

                if (snapshot.hasError)
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 60,
                            color: Colors.green[300],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Todo al día",
                          style: GoogleFonts.urbanist(
                            color: Colors.grey[800],
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "No hay recargas pendientes de aprobación",
                          style: GoogleFonts.urbanist(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;

                    // Extraemos los nuevos campos
                    return _RecargaCard(
                      recargaId: docs[i].id,
                      comensalId: data['comensalID'] ?? "",
                      nombre: data['nombre'] ?? "Usuario Desconocido",
                      monto: (data['monto'] ?? 0).toDouble(),
                      metodoPago: data['metodo_pago'] ?? 'Efectivo',
                      nroOperacion: data['nro_operacion'] ?? 'N/A',
                      fecha: data['fecha'] as Timestamp?,
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

// -----------------------------------------------------------------------------
// TARJETA PREMIUM DE APROBACIÓN
// -----------------------------------------------------------------------------
class _RecargaCard extends StatefulWidget {
  final String recargaId;
  final String comensalId;
  final String nombre;
  final double monto;
  final String metodoPago;
  final String nroOperacion;
  final Timestamp? fecha;

  const _RecargaCard({
    required this.recargaId,
    required this.comensalId,
    required this.nombre,
    required this.monto,
    required this.metodoPago,
    required this.nroOperacion,
    required this.fecha,
  });

  @override
  State<_RecargaCard> createState() => _RecargaCardState();
}

class _RecargaCardState extends State<_RecargaCard> {
  bool _isLoading = false;

  String _formatearFecha(Timestamp? timestamp) {
    if (timestamp == null) return "Fecha no disponible";
    DateTime date = timestamp.toDate();
    return DateFormat('dd MMM yyyy • hh:mm a').format(date);
  }

  Future<void> _procesarAprobacion() async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Confirmar Aprobación",
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        content: Text(
          "¿Aprobar la recarga de S/ ${widget.monto.toStringAsFixed(2)} enviada vía ${widget.metodoPago} para ${widget.nombre}?",
          style: GoogleFonts.urbanist(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "CANCELAR",
              style: GoogleFonts.urbanist(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "SÍ, APROBAR",
              style: GoogleFonts.urbanist(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference recargaRef = FirebaseFirestore.instance
          .collection('Recargas')
          .doc(widget.recargaId);
      DocumentReference usuarioRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.comensalId);

      batch.update(recargaRef, {'estado': 'aprobado'});
      batch.update(usuarioRef, {'saldo': FieldValue.increment(widget.monto)});

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Saldo aprobado para ${widget.nombre}",
                    style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al procesar: $e"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Configuración visual según método de pago
    Color mColor;
    IconData mIcon;
    if (widget.metodoPago == 'Yape') {
      mColor = const Color(0xFF74007A); // Morado Yape
      mIcon = Icons.qr_code_2_rounded;
    } else if (widget.metodoPago == 'Plin') {
      mColor = const Color(0xFF00B2A9); // Celeste Plin
      mIcon = Icons.qr_code_scanner_rounded;
    } else {
      mColor = const Color(0xFF1B5E20); // Verde Efectivo
      mIcon = Icons.payments_rounded;
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.comensalId)
          .snapshots(),
      builder: (context, snapshot) {
        String dni = "Cargando...";
        if (snapshot.hasData && snapshot.data!.exists) {
          dni = snapshot.data!.get('dni') ?? "No registrado";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
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
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: mColor, width: 6)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FILA 1: DATOS DEL USUARIO ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(mIcon, color: mColor, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nombre.toUpperCase(),
                              style: GoogleFonts.urbanist(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "DNI: $dni",
                              style: GoogleFonts.urbanist(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // --- FILA 2: DETALLES DE LA OPERACIÓN (RECUADRO GRIS ELEGANTE) ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Método",
                              style: GoogleFonts.urbanist(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.metodoPago,
                              style: GoogleFonts.urbanist(
                                color: mColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (widget.metodoPago != 'Efectivo')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Nro. Operación",
                                style: GoogleFonts.urbanist(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.nroOperacion,
                                style: GoogleFonts.urbanist(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Monto",
                              style: GoogleFonts.urbanist(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "S/ ${widget.monto.toStringAsFixed(2)}",
                              style: GoogleFonts.urbanist(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // --- FILA 3: FECHA Y BOTÓN DE ACCIÓN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatearFecha(widget.fecha),
                            style: GoogleFonts.urbanist(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            elevation: 2,
                            shadowColor: Colors.green.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: _isLoading ? null : _procesarAprobacion,
                          icon: _isLoading
                              ? const SizedBox()
                              : const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                          label: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "APROBAR",
                                  style: GoogleFonts.urbanist(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
