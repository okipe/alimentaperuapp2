import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RegistroSalidaView extends StatefulWidget {
  const RegistroSalidaView({super.key});

  @override
  State<RegistroSalidaView> createState() => _RegistroSalidaViewState();
}

class _RegistroSalidaViewState extends State<RegistroSalidaView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _fechaFiltro;

  final Color bgRed = const Color(0xFF8B1D1D); // Rojo institucional que usabas
  final Color bgColor = const Color(0xFFF0F4F1);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // --- HEADER PREMIUM ROJO ---
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 60,
                  bottom: 20,
                  left: 22,
                  right: 22,
                ),
                decoration: BoxDecoration(
                  color: bgRed,
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
                            "HISTORIAL DE SALIDAS",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // LÓGICA DE FILTRO INTACTA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _fechaFiltro == null
                                ? "Mostrando: Todas las fechas"
                                : "Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaFiltro!)}",
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaFiltro ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            setState(() => _fechaFiltro = picked);
                          },
                          icon: const Icon(Icons.filter_list_rounded, size: 16),
                          label: Text(
                            "Filtrar",
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: bgRed,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_fechaFiltro != null)
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                setState(() => _fechaFiltro = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- TABLA DE DATOS (LÓGICA INTACTA) ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('Movimientos')
                      .where('tipo', isEqualTo: 'SALIDA_MENU')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    var docs = snapshot.data!.docs;
                    if (_fechaFiltro != null) {
                      docs = docs.where((d) {
                        DateTime fechaDoc = (d['fecha'] as Timestamp).toDate();
                        return fechaDoc.year == _fechaFiltro!.year &&
                            fechaDoc.month == _fechaFiltro!.month &&
                            fechaDoc.day == _fechaFiltro!.day;
                      }).toList();
                    }

                    docs.sort(
                      (a, b) => (b['fecha'] as Timestamp).compareTo(
                        a['fecha'] as Timestamp,
                      ),
                    );

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No hay registros para esta fecha.",
                          style: GoogleFonts.dmSans(color: Colors.grey),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            bgRed.withOpacity(0.05),
                          ),
                          columnSpacing: isWeb ? screenWidth * 0.08 : 25,
                          horizontalMargin: 20,
                          columns: [
                            DataColumn(
                              label: Text(
                                'FECHA',
                                style: GoogleFonts.dmSans(
                                  color: bgRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'PLATO',
                                style: GoogleFonts.dmSans(
                                  color: bgRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'INSUMO',
                                style: GoogleFonts.dmSans(
                                  color: bgRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CANT.',
                                style: GoogleFonts.dmSans(
                                  color: bgRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'COCINERA',
                                style: GoogleFonts.dmSans(
                                  color: bgRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          rows: docs.map((d) {
                            var data = d.data() as Map<String, dynamic>;
                            DateTime f = (data['fecha'] as Timestamp).toDate();
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(f),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    data['menu'] ?? '-',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    data['producto'] ?? '-',
                                    style: GoogleFonts.dmSans(fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "-${data['cantidad_utilizada']} ${data['unidad'] ?? 'kg'}",
                                    style: GoogleFonts.dmSans(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    data['cocinera'] ?? '-',
                                    style: GoogleFonts.dmSans(fontSize: 13),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
