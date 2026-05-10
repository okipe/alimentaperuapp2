import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReportesView extends StatefulWidget {
  const ReportesView({super.key});

  @override
  State<ReportesView> createState() => _ReportesViewState();
}

class _ReportesViewState extends State<ReportesView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- COLORES PREMIUM ALIMENTA PERÚ ---
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  // Filtro de mes actual
  final DateTime now = DateTime.now();

  // SOLUCIÓN DEFINITIVA AL ERROR ROJO: Lista manual de meses
  final List<String> meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    // Obtenemos el mes actual en texto sin usar intl con 'es'
    String mesActual = meses[now.month - 1].toUpperCase();

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // --- HEADER PREMIUM ---
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 60,
                  bottom: 40,
                  left: 22,
                  right: 22,
                ),
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
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
                            "ADMINISTRACIÓN",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Reportes de Gestión",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Resumen de $mesActual ${now.year}", // <- AQUÍ ESTÁ LA CORRECCIÓN
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),

          // --- CUERPO DE REPORTES ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "INDICADORES PRINCIPALES",
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- FILA DE KPIs ---
                  Row(
                    children: [
                      Expanded(child: _buildRacionesMesKPI()),
                      const SizedBox(width: 15),
                      Expanded(child: _buildIngresosMesKPI()),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- SECCIÓN: PLATOS MÁS PREPARADOS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "PLATOS MÁS PREPARADOS",
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.grey[600],
                        ),
                      ),
                      Icon(Icons.restaurant, size: 16, color: accentGreen),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTopMenus(),

                  const SizedBox(height: 30),

                  // --- SECCIÓN: RECARGAS RECIENTES ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ÚLTIMAS RECARGAS APROBADAS",
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.grey[600],
                        ),
                      ),
                      Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: accentGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildUltimasRecargas(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGETS DE REPORTES (CONECTADOS A FIREBASE)
  // ===========================================================================

  // 1. KPI Raciones Servidas
  Widget _buildRacionesMesKPI() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Menus').snapshots(),
      builder: (context, snapshot) {
        int totalRaciones = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            Timestamp? fechaTs = data['fecha_registro'] as Timestamp?;
            if (fechaTs != null &&
                fechaTs.toDate().month == now.month &&
                fechaTs.toDate().year == now.year) {
              totalRaciones += (data['raciones'] as num?)?.toInt() ?? 0;
            }
          }
        }
        return _buildKPICard(
          titulo: "Raciones Servidas",
          valor: totalRaciones.toString(),
          subtitulo: "Este mes",
          icono: Icons.room_service_rounded,
          colorIcono: const Color(0xFFE8924A),
        );
      },
    );
  }

  // 2. KPI Ingresos Recargas
  Widget _buildIngresosMesKPI() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Recargas')
          .where('estado', isEqualTo: 'aprobado')
          .snapshots(),
      builder: (context, snapshot) {
        double totalIngresos = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            Timestamp? fechaTs = data['fecha'] as Timestamp?;
            if (fechaTs != null &&
                fechaTs.toDate().month == now.month &&
                fechaTs.toDate().year == now.year) {
              totalIngresos += (data['monto'] as num?)?.toDouble() ?? 0;
            }
          }
        }
        return _buildKPICard(
          titulo: "Ingresos Recargas",
          valor: "S/ ${totalIngresos.toStringAsFixed(2)}",
          subtitulo: "Este mes",
          icono: Icons.account_balance_wallet_rounded,
          colorIcono: const Color(0xFF3B82C4),
        );
      },
    );
  }

  // 3. Diseño de la Tarjeta KPI
  Widget _buildKPICard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icono,
    required Color colorIcono,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorIcono.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: colorIcono, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            valor,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            titulo,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            subtitulo,
            style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // 4. Lista de Platos Top
  Widget _buildTopMenus() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Menus').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        Map<String, int> conteoPlatos = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          String plato = data['Plato'] ?? 'Desconocido';
          conteoPlatos[plato] = (conteoPlatos[plato] ?? 0) + 1;
        }

        var sortedPlatos = conteoPlatos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedPlatos.isEmpty) {
          return Center(
            child: Text(
              "Aún no hay menús registrados.",
              style: GoogleFonts.dmSans(color: Colors.grey),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Column(
            children: sortedPlatos.take(3).map((e) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: bgColor,
                  child: Icon(
                    Icons.restaurant_menu,
                    color: accentGreen,
                    size: 18,
                  ),
                ),
                title: Text(
                  e.key,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                trailing: Text(
                  "${e.value} veces",
                  style: GoogleFonts.dmSans(
                    color: accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 5. Lista de Recargas Recientes
  Widget _buildUltimasRecargas() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Recargas')
          .where('estado', isEqualTo: 'aprobado')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final dateA =
              (a.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
          final dateB =
              (b.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
          return (dateB ?? Timestamp.now()).compareTo(dateA ?? Timestamp.now());
        });

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "Aún no hay recargas aprobadas.",
              style: GoogleFonts.dmSans(color: Colors.grey),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Column(
            children: docs.take(4).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              Timestamp? f = data['fecha'] as Timestamp?;

              // SEGUNDA CORRECCIÓN: Formato seguro con puros números, nunca falla.
              String fechaStr = f != null
                  ? DateFormat('dd/MM/yyyy • hh:mm a').format(f.toDate())
                  : '';

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    color: Colors.green[700],
                    size: 20,
                  ),
                ),
                title: Text(
                  data['nombre'] ?? 'Usuario',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  "${data['metodo_pago'] ?? 'Efectivo'} • $fechaStr",
                  style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey),
                ),
                trailing: Text(
                  "+ S/ ${data['monto']}",
                  style: GoogleFonts.dmSans(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
