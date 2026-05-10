import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReporteStockView extends StatefulWidget {
  const ReporteStockView({super.key});
  @override
  State<ReporteStockView> createState() => _ReporteStockViewState();
}

class _ReporteStockViewState extends State<ReporteStockView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? catF;
  String? prodF;

  final Map<String, List<String>> listaMaestra = {
    'Abarrotes': [
      'Arroz',
      'Azúcar',
      'Sal',
      'Aceite vegetal',
      'Fideos',
      'Huevos',
    ],
    'Menestras': ['Lenteja', 'Frejol', 'Garbanzo'],
    'Verduras': ['Papa', 'Cebolla', 'Tomate', 'Zanahoria'],
    'Carnes': ['Pollo', 'Carne de res', 'Pescado'],
  };

  // Colores Premium Alimenta Perú
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                            "STOCK ACTUAL",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
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

          // --- CUERPO ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                          _buildLabel("Categoría"),
                          _buildDrop(
                            catF,
                            listaMaestra.keys.toList(),
                            (val) => setState(() {
                              catF = val;
                              prodF = null;
                            }),
                          ),
                          if (catF != null) ...[
                            const SizedBox(height: 15),
                            _buildLabel("Producto"),
                            _buildDrop(
                              prodF,
                              listaMaestra[catF!]!,
                              (val) => setState(() => prodF = val),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    child: Text(
                      "AUDITORÍA DE STOCK POR PRODUCTO",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF7A9E8A),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  if (prodF != null) _buildTablaDetalle(),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      "RESUMEN DE ALERTAS",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red[900],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTablaAlertasGlobal(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS ORIGINALES DE LÓGICA ---
  Widget _buildTablaDetalle() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Productos')
          .where('nombre_busqueda', isEqualTo: prodF!.toUpperCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // ¡AQUÍ ESTÁ LA MAGIA! Filtramos los documentos para ocultar los que tienen 0
        var docs = snapshot.data!.docs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          return (data['cantidad'] as num).toDouble() > 0;
        }).toList();

        double totalStock = 0;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Nombre",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Categoría",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Vencimiento",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Stock",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            if (docs.isEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F4F1))),
                ),
                child: Text(
                  "No hay stock disponible para este producto.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: Colors.grey),
                ),
              )
            else
              ...docs.map((d) {
                var data = d.data() as Map<String, dynamic>;
                totalStock += (data['cantidad'] as num).toDouble();
                String fv = DateFormat(
                  'dd/MM/yy',
                ).format((data['fecha_vencimiento'] as Timestamp).toDate());

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F4F1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          data['nombre'],
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: const Color(0xFF1C3326),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          data['categoria'] ?? "-",
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          fv,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "${data['cantidad']} ${data['unidad']}",
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D52),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            _buildCardTotal(totalStock),
          ],
        );
      },
    );
  }

  Widget _buildTablaAlertasGlobal() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Productos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        Map<String, double> r = {};
        for (var doc in snapshot.data!.docs) {
          r[doc['nombre']] =
              (r[doc['nombre']] ?? 0) + (doc['cantidad'] as num).toDouble();
        }
        List<Map<String, dynamic>> alertas = [];
        listaMaestra.forEach((cat, prods) {
          for (var p in prods) {
            double s = r[p] ?? 0;
            if (s <= 2) alertas.add({'p': p, 'c': cat, 's': s});
          }
        });

        return Column(
          children: alertas.map((item) {
            bool es0 =
                item['s'] <=
                0; // Ajustado para capturar 0 o negativos por si acaso
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['p'],
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C3326),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "${item['s']}",
                      style: GoogleFonts.dmSans(
                        color: es0 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: es0 ? Colors.red[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        es0 ? "QUIEBRE" : "BAJO",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: es0 ? Colors.red : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: darkGreen.withOpacity(0.7),
      ),
    ),
  );

  Widget _buildDrop(String? v, List<String> i, Function(String?) onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButtonFormField<String>(
            value: v,
            isExpanded: true,
            items: i
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: GoogleFonts.dmSans(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      );

  Widget _buildCardTotal(double t) => Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "TOTAL DISPONIBLE",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D52),
          ),
        ),
        Text(
          "${t.toStringAsFixed(1)}",
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
      ],
    ),
  );
}
