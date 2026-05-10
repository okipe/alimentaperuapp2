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
  DateTime _fechaFiltro = DateTime.now();

  final Color bgRed = const Color(0xFF8B1D1D);
  final Color bgColor = const Color(0xFFF0F4F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildFiltroFechaUI(),
          Expanded(child: _buildTablaInsumosDetallada()),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 60, bottom: 30, left: 22, right: 22),
    decoration: BoxDecoration(
      color: bgRed,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            "CONTROL DE INSUMOS",
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 45),
      ],
    ),
  );

  Widget _buildFiltroFechaUI() => Padding(
    padding: const EdgeInsets.all(22.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "SALIDAS DEL DÍA",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A4D2E),
          ),
        ),
        InkWell(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _fechaFiltro,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _fechaFiltro = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: bgRed),
                const SizedBox(width: 10),
                Text(
                  DateFormat('dd/MM/yyyy').format(_fechaFiltro),
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: bgRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildTablaInsumosDetallada() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 22),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    child: StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Movimientos')
          .where('tipo', whereIn: ['SALIDA_MENU', 'SALIDA_MERMA'])
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs.where((d) {
          if (d['fecha'] == null) return false;
          DateTime f = (d['fecha'] as Timestamp).toDate();
          return f.day == _fechaFiltro.day &&
              f.month == _fechaFiltro.month &&
              f.year == _fechaFiltro.year;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text("No hay datos para esta fecha"));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('HORA')),
              DataColumn(label: Text('INSUMO')),
              DataColumn(label: Text('CANTIDAD')),
              DataColumn(label: Text('MENÚ')),
            ],
            rows: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              DateTime h = (data['fecha'] as Timestamp).toDate();
              bool isMerma = data['tipo'] == 'SALIDA_MERMA';
              return DataRow(
                cells: [
                  DataCell(Text(DateFormat('HH:mm').format(h))),
                  DataCell(Text(data['producto'] ?? '-')),
                  DataCell(
                    Text(
                      "-${data['cantidad_utilizada']} ${data['unidad']}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(Text(isMerma ? "MERMA" : (data['menu'] ?? "MENÚ"))),
                ],
              );
            }).toList(),
          ),
        );
      },
    ),
  );
}
