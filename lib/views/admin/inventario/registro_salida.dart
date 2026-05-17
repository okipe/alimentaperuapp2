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

  // Rango de fechas por defecto: Hoy
  DateTimeRange _rangoFechas = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  final Color deepRed = const Color(0xFF8B0000);
  final Color bgRed = const Color(0xFF8B1D1D);
  final Color lightGray = const Color(0xFFF4F4F4);
  final Color accentGreen = const Color(0xFF2E7D52);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // --- CABECERA ORIGINAL PRESERVADA ---
  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
    decoration: BoxDecoration(
      color: bgRed,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
      boxShadow: [
        BoxShadow(
          color: bgRed.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        Text(
          "REPORTE DE SALIDAS",
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    ),
  );

  // --- NUEVA BARRA DE FILTROS POR RANGO ---
  Widget _buildFilterBar() => Padding(
    padding: const EdgeInsets.all(20),
    child: InkWell(
      onTap: _seleccionarRangoFechas,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: deepRed, size: 22),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Periodo de consulta",
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "${DateFormat('dd/MM/yy').format(_rangoFechas.start)} - ${DateFormat('dd/MM/yy').format(_rangoFechas.end)}",
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.swap_horiz, color: Colors.grey),
          ],
        ),
      ),
    ),
  );

  // --- CONTENIDO PRINCIPAL ---
  Widget _buildMainContent() {
    return StreamBuilder(
      stream: _firestore.collection('Menues').snapshots(),
      builder: (context, _) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _obtenerDatosConsolidados(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildMensajeEstado(
                "Error al conectar con la base de datos",
                Icons.cloud_off,
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return _buildMensajeEstado(
                "No encontramos registros en este periodo",
                Icons.search_off,
              );
            }

            return _buildTablaProfesional(data);
          },
        );
      },
    );
  }

  // --- DISEÑO DE TABLA ROJO PROFESIONAL ---
  Widget _buildTablaProfesional(List<Map<String, dynamic>> lista) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(deepRed),
              columnSpacing: 12,
              horizontalMargin: 12,
              columns: [
                _headerCell("HORA"),
                _headerCell("INSUMO"),
                _headerCell("CANT."),
                _headerCell("MOTIVO"),
              ],
              rows: lista
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            DateFormat('HH:mm').format(item['hora']),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        DataCell(
                          Text(
                            item['producto'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "-${item['cantidad']} ${item['unidad']}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            item['motivo'],
                            style: TextStyle(
                              color: item['esMerma']
                                  ? Colors.orange[800]
                                  : accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // --- LÓGICA DE DATOS OPTIMIZADA ---
  Future<List<Map<String, dynamic>>> _obtenerDatosConsolidados() async {
    List<Map<String, dynamic>> temp = [];

    // 1. Mermas
    var snapSalidas = await _firestore.collection('Salidas').get();
    for (var doc in snapSalidas.docs) {
      DateTime f = (doc['fecha'] as Timestamp).toDate();
      if (_estaEnRango(f)) {
        temp.add({
          'hora': f,
          'producto': doc['producto'],
          'cantidad': doc['cantidad_utilizada'],
          'unidad': doc['unidad'],
          'motivo': "MERMA",
          'esMerma': true,
        });
      }
    }

    // 2. Consumos de Menú
    var snapMenues = await _firestore.collection('Menues').get();
    for (var doc in snapMenues.docs) {
      DateTime f = (doc['fecha'] as Timestamp).toDate();
      if (_estaEnRango(f)) {
        List insumos = doc['insumos'] ?? [];
        for (var i in insumos) {
          temp.add({
            'hora': f,
            'producto': i['producto'],
            'cantidad': i['cantidad'],
            'unidad': i['unidad'],
            'motivo': doc['plato'].toString().toUpperCase(),
            'esMerma': false,
          });
        }
      }
    }

    temp.sort((a, b) => b['hora'].compareTo(a['hora']));
    return temp;
  }

  bool _estaEnRango(DateTime fecha) {
    final f = DateTime(fecha.year, fecha.month, fecha.day);
    final inicio = DateTime(
      _rangoFechas.start.year,
      _rangoFechas.start.month,
      _rangoFechas.start.day,
    );
    final fin = DateTime(
      _rangoFechas.end.year,
      _rangoFechas.end.month,
      _rangoFechas.end.day,
    );
    return f.isAtSameMomentAs(inicio) ||
        f.isAtSameMomentAs(fin) ||
        (f.isAfter(inicio) && f.isBefore(fin));
  }

  DataColumn _headerCell(String t) => DataColumn(
    label: Text(
      t,
      style: GoogleFonts.dmSans(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    ),
  );

  Widget _buildMensajeEstado(String msg, IconData icon) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 10),
        Text(
          msg,
          style: GoogleFonts.dmSans(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Future<void> _seleccionarRangoFechas() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _rangoFechas,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: deepRed)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _rangoFechas = picked);
  }
}
