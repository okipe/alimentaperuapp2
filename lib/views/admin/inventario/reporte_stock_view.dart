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

  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildFiltros(),
          // MEJORA: Icono cuando no hay datos seleccionados
          Expanded(
            child: prodF == null ? _buildNoDataIcon() : _buildResultados(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 60, bottom: 40, left: 22, right: 22),
    decoration: BoxDecoration(
      color: darkGreen,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            "INVENTARIO DE PRODUCTOS",
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );

  Widget _buildFiltros() => Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDrop(
            "Categoría",
            catF,
            listaMaestra.keys.toList(),
            (v) => setState(() {
              catF = v;
              prodF = null;
            }),
          ),
          if (catF != null) ...[
            const SizedBox(height: 15),
            _buildDrop(
              "Producto",
              prodF,
              listaMaestra[catF!]!,
              (v) => setState(() => prodF = v),
            ),
          ],
        ],
      ),
    ),
  );

  // Widget para mostrar cuando no hay selección
  Widget _buildNoDataIcon() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 80,
          color: darkGreen.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 15),
        Text(
          "Selecciona un producto para auditar",
          style: GoogleFonts.dmSans(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildResultados() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Productos')
          .where('nombre', isEqualTo: prodF)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs
            .where((d) => (d['cantidad'] ?? 0).toDouble() > 0)
            .toList();
        double total = docs.fold(
          0.0,

          (valorAcumulado, d) =>
              valorAcumulado + (d['cantidad'] ?? 0).toDouble(),
        );

        return Column(
          children: [
            _buildCardTotal(total),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) =>
                    _buildLoteItem(docs[index].data() as Map<String, dynamic>),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoteItem(Map<String, dynamic> data) {
    final DateTime now = DateTime.now();
    final dynamic fechaData = data['fecha_vencimiento'];

    String fvString = "Sin fecha";
    Color estadoColor = Colors.green; // Verde por defecto (Saludable)
    bool esAlerta = false;

    if (fechaData != null && fechaData is Timestamp) {
      DateTime fvDate = fechaData.toDate();
      fvString = DateFormat('dd/MM/yyyy').format(fvDate);
      int diasRestantes = fvDate.difference(now).inDays;

      // LÓGICA DE COLORES SOLICITADA
      if (diasRestantes <= 0) {
        estadoColor = Colors.red; // Vencido
        esAlerta = true;
      } else if (diasRestantes <= 7) {
        estadoColor = Colors.orange; // Alerta 7 días antes
        esAlerta = true;
      } else {
        estadoColor = Colors.green; // Saludable
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: esAlerta
              ? estadoColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: estadoColor,
          ), // Indicador de estado
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['nombre'] ?? "Insumo",
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Vence: $fvString",
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: estadoColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${data['cantidad'] ?? 0} ${data['unidad'] ?? 'kg'}",
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
        ],
      ),
    );
  }

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
          t.toStringAsFixed(1),
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
      ],
    ),
  );

  Widget _buildDrop(
    String h,
    String? v,
    List<String> i,
    Function(String?) onC,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: bgColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        initialValue: v,
        isExpanded: true,
        hint: Text(h),
        items: i
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onC,
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    ),
  );
}
