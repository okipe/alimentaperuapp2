import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReportesDashboardView extends StatefulWidget {
  const ReportesDashboardView({super.key});

  @override
  State<ReportesDashboardView> createState() => _ReportesDashboardViewState();
}

class _ReportesDashboardViewState extends State<ReportesDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Colores Institucionales Alimenta Perú
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color accentGreen = const Color(0xFF2E7D52);
  final Color bgColor = const Color(0xFFF8FAF9);

  DateTime _selectedDate = DateTime.now();
  String _filtroVencimiento = "Todos";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // --- HEADER INSTITUCIONAL PREMIUM ---
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopNav(),
                  Text(
                    "Panel de Reportes",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- TABBAR CENTRADO ---
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.5),
                    labelStyle: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    tabs: const [
                      Tab(text: "VENCIMIENTOS"),
                      Tab(text: "RACIONES DIARIAS"),
                      Tab(text: "STOCK TOTAL"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- CONTENIDO ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFIFOView(), // Pestaña 1: FIFO (Sin ceros)
                _buildRacionesView(), // Pestaña 2: Raciones (Detalle por día)
                _buildStockTotalView(), // Pestaña 3: Stock Total (Consolidado)
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. VISTA FIFO (SIN PRODUCTOS EN CERO) ---
  Widget _buildFIFOView() {
    return Column(
      children: [
        _buildImprovedFilterChips(), // Chips Centrados
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Productos')
                .where(
                  'cantidad',
                  isGreaterThan: 0,
                ) // Filtro: Solo lo que hay en almacén
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var items = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['fecha_vencimiento'] == null) return false;
                final venc = (data['fecha_vencimiento'] as Timestamp).toDate();
                final dias = venc.difference(DateTime.now()).inDays;

                if (_filtroVencimiento == "Vencido") return dias < 0;
                if (_filtroVencimiento == "Próximo") {
                  return dias >= 0 && dias <= 7;
                }
                if (_filtroVencimiento == "Vigente") return dias > 7;
                return true;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildFIFOListTile(items[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 2. VISTA RACIONES (DETALLE POR DÍA) ---
  Widget _buildRacionesView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Fecha seleccionada:",
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
              ),
              InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: accentGreen, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: TextStyle(
                        color: accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Menues').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var filtrados = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['fecha'] == null) return false;
                DateTime f = (data['fecha'] as Timestamp).toDate();
                return f.day == _selectedDate.day &&
                    f.month == _selectedDate.month &&
                    f.year == _selectedDate.year;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: filtrados.length,
                itemBuilder: (context, index) {
                  final data = filtrados[index].data() as Map<String, dynamic>;
                  return _buildSimpleCard(
                    data['plato'] ?? "Menú",
                    "${data['raciones']} Raciones",
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 3. STOCK TOTAL (CONSOLIDADO) ---
  Widget _buildStockTotalView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Productos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, double> suma = {};
        Map<String, String> unids = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          String nombre = (data['nombre'] ?? "S/N").toString().trim();
          double cant = (data['cantidad'] ?? 0).toDouble();
          suma[nombre] = (suma[nombre] ?? 0) + cant;
          unids[nombre] = data['unidad'] ?? 'unid'; // Protección contra errores
        }

        var productos = suma.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            String p = productos[index];
            double total = suma[p]!;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade100),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: total == 0
                      ? Colors.red.shade50
                      : darkGreen.withOpacity(0.1),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: total == 0 ? Colors.red : darkGreen,
                    size: 20,
                  ),
                ),
                title: Text(
                  p,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  "$total ${unids[p]}",
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    color: total == 0 ? Colors.red : darkGreen,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- COMPONENTES UI: FILTROS CENTRADOS ---
  Widget _buildImprovedFilterChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ["Todos", "Vigente", "Próximo", "Vencido"].map((f) {
              bool isSelected = _filtroVencimiento == f;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _filtroVencimiento = f),
                  selectedColor: accentGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? accentGreen : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFIFOListTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final venc = (data['fecha_vencimiento'] as Timestamp).toDate();
    final dias = venc.difference(DateTime.now()).inDays;

    Color colorEstado = dias < 0
        ? Colors.red
        : (dias <= 7 ? Colors.orange : Colors.green);
    IconData iconEstado = dias < 0
        ? Icons.dangerous
        : (dias <= 7 ? Icons.warning_rounded : Icons.check_circle_rounded);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Icon(iconEstado, color: colorEstado, size: 28),
        title: Text(
          data['nombre'] ?? "Producto",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Vencimiento: ${DateFormat('dd/MM/yyyy').format(venc)}"),
        trailing: Text(
          "${data['cantidad']} ${data['unidad'] ?? 'und'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSimpleCard(String title, String trailing) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          trailing,
          style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          const Icon(Icons.analytics_outlined, color: Colors.white54, size: 20),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
