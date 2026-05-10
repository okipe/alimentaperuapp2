import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReportesView extends StatelessWidget {
  const ReportesView({super.key});

  // Colores Premium Alimenta Perú
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "REPORTES DE GESTIÓN",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: darkGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // USAMOS 'Menues' que es la colección donde guardas la producción real
        stream: FirebaseFirestore.instance
            .collection('Menues')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState("Error al conectar con el inventario");
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState("No hay registros de producción aún");
          }

          // Procesamiento de datos Senior para los indicadores superiores
          double racionesTotales = 0;
          int totalServicios = snapshot.data!.docs.length;
          final docs = snapshot.data!.docs;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            // Sumamos raciones asegurando que no explote si el dato es nulo
            racionesTotales += (data['raciones'] ?? 0).toDouble();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Resumen de Impacto Social"),
                const SizedBox(height: 15),

                Row(
                  children: [
                    _cardMetrica(
                      "Raciones Totales",
                      racionesTotales.toStringAsFixed(0),
                      Icons.restaurant_rounded,
                      accentGreen,
                    ),
                    const SizedBox(width: 15),
                    _cardMetrica(
                      "Días Activos",
                      totalServicios.toString(),
                      Icons.calendar_today_rounded,
                      const Color(0xFFC28D05),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                _buildSectionTitle("Historial Detallado"),
                const SizedBox(height: 15),

                // Listado de producción con diseño de tarjetas limpias
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final DateTime fecha = (data['fecha'] as Timestamp)
                        .toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: bgColor,
                          child: Icon(
                            Icons.soup_kitchen_rounded,
                            color: darkGreen,
                          ),
                        ),
                        title: Text(
                          data['plato'] ?? "Menú sin nombre",
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        subtitle: Text(
                          "Cocinera: ${data['cocinera']}\n${DateFormat('dd/MM/yyyy - HH:mm').format(fecha)}",
                          style: GoogleFonts.dmSans(fontSize: 12, height: 1.5),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${data['raciones']}",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight
                                    .w900, // CORRECCIÓN: Usamos w900 para el peso máximo
                                fontSize: 18,
                                color: accentGreen,
                              ),
                            ),
                            const Text(
                              "RACIONES",
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: darkGreen,
      ),
    );
  }

  Widget _cardMetrica(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 15),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            msg,
            style: GoogleFonts.dmSans(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Text(error, style: const TextStyle(color: Colors.red)),
    );
  }
}
