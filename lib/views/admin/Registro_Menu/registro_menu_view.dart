import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RegistroMenuView extends StatefulWidget {
  const RegistroMenuView({super.key});

  @override
  State<RegistroMenuView> createState() => _RegistroMenuViewState();
}

class _RegistroMenuViewState extends State<RegistroMenuView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // LÓGICA DE CONTROLADORES E INVENTARIO
  final TextEditingController _racionesController = TextEditingController();
  final TextEditingController _cocineraController = TextEditingController();
  String? _platoSeleccionado;
  List<Map<String, dynamic>> ingredientesSeleccionados = [];

  int _refreshKey = 0;

  final List<String> _platosSugeridos = [
    "Arroz con pollo",
    "Tallarines rojos",
    "Seco de pollo",
    "Lentejas con arroz",
    "Estofado de pollo",
    "Ají de gallina",
    "Aguadito de pollo",
    "Sopa de mote",
  ];

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

  // COLORES PREMIUM ALIMENTA PERÚ
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  // --- FUNCIÓN DE REGISTRO CON LÓGICA FIFO (PRIMERO EN VENCER, PRIMERO EN SALIR) ---
  Future<void> _finalizarRegistro() async {
    if (_platoSeleccionado == null ||
        _platoSeleccionado!.trim().isEmpty ||
        ingredientesSeleccionados.isEmpty ||
        _cocineraController.text.isEmpty ||
        _racionesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ Por favor, completa todos los campos y añade insumos",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      WriteBatch batch = _firestore.batch();
      final DateTime now = DateTime.now();
      final Timestamp timestamp = Timestamp.fromDate(now);

      for (var ing in ingredientesSeleccionados) {
        double cantidadRequerida = (ing['cantidad_usada'] as num).toDouble();

        var snap = await _firestore
            .collection('Productos')
            .where('nombre', isEqualTo: ing['nombre'])
            .get();

        var lotes = snap.docs.toList();
        lotes.removeWhere((doc) => (doc.data()['cantidad'] as num) <= 0);

        lotes.sort((a, b) {
          final dataA = a.data();
          final dataB = b.data();
          Timestamp? fechaA = dataA['fecha_vencimiento'] is Timestamp
              ? dataA['fecha_vencimiento']
              : null;
          Timestamp? fechaB = dataB['fecha_vencimiento'] is Timestamp
              ? dataB['fecha_vencimiento']
              : null;
          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1;
          if (fechaB == null) return -1;
          return fechaA.compareTo(fechaB);
        });

        for (var lote in lotes) {
          if (cantidadRequerida <= 0) break;
          double stockDisponible = (lote.data()['cantidad'] as num).toDouble();
          double cantidadADescontar = (stockDisponible >= cantidadRequerida)
              ? cantidadRequerida
              : stockDisponible;
          cantidadRequerida -= cantidadADescontar;
          batch.update(lote.reference, {
            'cantidad': stockDisponible - cantidadADescontar,
          });
        }

        DocumentReference movRef = _firestore.collection('Movimientos').doc();
        batch.set(movRef, {
          'producto': ing['nombre'],
          'cantidad_utilizada': ing['cantidad_usada'],
          'unidad': ing['unidad'],
          'tipo': 'SALIDA_MENU',
          'fecha': timestamp,
          'menu': _platoSeleccionado,
          'cocinera': _cocineraController.text,
          'raciones': int.tryParse(_racionesController.text) ?? 0,
        });
      }

      DocumentReference menuDiarioRef = _firestore.collection('Menus').doc();
      batch.set(menuDiarioRef, {
        'Plato': _platoSeleccionado,
        'cocinera': _cocineraController.text,
        'comedor': "Villa El Salvador",
        'fecha_registro': timestamp,
        'raciones': int.tryParse(_racionesController.text) ?? 0,
      });

      await batch.commit();

      setState(() {
        _refreshKey++;
        ingredientesSeleccionados.clear();
        _racionesController.clear();
        _cocineraController.clear();
        _platoSeleccionado = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "✅ MENÚ REGISTRADO Y STOCK ACTUALIZADO",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // HEADER
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
                            "REGISTRO DIARIO",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Menú del Día",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // CUERPO DEL FORMULARIO
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("NOMBRE DEL PLATO"),
                        Autocomplete<String>(
                          optionsBuilder: (v) => _platosSugeridos.where(
                            (p) =>
                                p.toLowerCase().contains(v.text.toLowerCase()),
                          ),
                          onSelected: (s) =>
                              setState(() => _platoSeleccionado = s),
                          fieldViewBuilder: (ctx, ctrl, focus, onSub) =>
                              TextField(
                                controller: ctrl,
                                focusNode: focus,
                                onChanged: (val) => _platoSeleccionado = val,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.restaurant_menu,
                                    color: darkGreen.withOpacity(0.4),
                                  ),
                                  hintText: "Ej: Seco de Pollo",
                                  filled: true,
                                  fillColor: bgColor.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("RACIONES"),
                                  _buildInputStyled(
                                    _racionesController,
                                    Icons.groups,
                                    true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("COCINERA"),
                                  _buildCocineraDropdown(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLabel("INSUMOS AÑADIDOS"),
                            TextButton.icon(
                              onPressed: _abrirDialogoInsumos,
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: Color(0xFF2E7D52),
                              ),
                              label: Text(
                                "Añadir",
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E7D52),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTablaInsumosTemporales(),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: _finalizarRegistro,
                            icon: const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              "GUARDAR REGISTRO TOTAL",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  _buildHistorialCorregido(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: accentGreen.withOpacity(0.7),
      ),
    ),
  );

  Widget _buildInputStyled(
    TextEditingController ctrl,
    IconData icon,
    bool isNum,
  ) => TextField(
    controller: ctrl,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: darkGreen.withOpacity(0.4)),
      filled: true,
      fillColor: bgColor.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _buildCocineraDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: bgColor.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('cocineras').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(),
            ),
          );
        List<DropdownMenuItem<String>> items = snapshot.data!.docs.map((doc) {
          final fullName = "${doc['nombre'] ?? ''} ${doc['apellido'] ?? ''}"
              .trim();
          return DropdownMenuItem(
            value: fullName,
            child: Text(fullName, style: GoogleFonts.dmSans(fontSize: 14)),
          );
        }).toList();
        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            hint: const Text("Elegir..."),
            value: _cocineraController.text.isEmpty
                ? null
                : _cocineraController.text,
            items: items,
            onChanged: (val) {
              if (val != null) setState(() => _cocineraController.text = val);
            },
          ),
        );
      },
    ),
  );

  Widget _buildTablaInsumosTemporales() => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: DataTable(
      headingRowColor: WidgetStateProperty.all(bgColor.withOpacity(0.5)),
      columns: const [
        DataColumn(label: Text("Insumo")),
        DataColumn(label: Text("Cant.")),
      ],
      rows: ingredientesSeleccionados
          .map(
            (e) => DataRow(
              cells: [
                DataCell(Text(e['nombre'])),
                DataCell(
                  Text(
                    "${e['cantidad_usada']} ${e['unidad']}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );

  Widget _buildHistorialCorregido() => StreamBuilder<QuerySnapshot>(
    key: ValueKey('historial_$_refreshKey'),
    stream: _firestore.collection('Movimientos').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const CircularProgressIndicator();
      var docs = snapshot.data!.docs
          .where((d) => d['tipo'] == 'SALIDA_MENU')
          .toList();
      docs.sort(
        (a, b) => (b['fecha'] as Timestamp).compareTo(a['fecha'] as Timestamp),
      );
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(darkGreen.withOpacity(0.05)),
          columns: const [
            DataColumn(label: Text("Fecha")),
            DataColumn(label: Text("Plato")),
            DataColumn(label: Text("Insumo")),
            DataColumn(label: Text("Cant.")),
          ],
          rows: docs.take(10).map((d) {
            DateTime f = (d['fecha'] as Timestamp).toDate();
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    DateFormat('dd/MM HH:mm').format(f),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                DataCell(
                  Text(
                    d['menu'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    d['producto'] ?? '-',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                DataCell(
                  Text(
                    "-${d['cantidad_utilizada']} ${d['unidad']}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    },
  );

  // --- DIÁLOGO PARA AÑADIR INSUMOS CON VALIDACIÓN DE STOCK ---
  void _abrirDialogoInsumos() {
    String? catDialog;
    String? prodDialog;
    String unidadDialog = 'kg';
    final TextEditingController cantCtrl = TextEditingController();
    bool verificando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Añadir Insumo",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: catDialog,
                    decoration: InputDecoration(
                      labelText: "Categoría",
                      filled: true,
                      fillColor: bgColor,
                      border: InputBorder.none,
                    ),
                    items: listaMaestra.keys
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        catDialog = val;
                        prodDialog = null;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  if (catDialog != null)
                    DropdownButtonFormField<String>(
                      value: prodDialog,
                      decoration: InputDecoration(
                        labelText: "Producto",
                        filled: true,
                        fillColor: bgColor,
                        border: InputBorder.none,
                      ),
                      items: listaMaestra[catDialog]!
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setStateDialog(() => prodDialog = val),
                    ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cantCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Cantidad",
                            filled: true,
                            fillColor: bgColor,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unidadDialog,
                          items: ['kg', 'lt', 'unid']
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setStateDialog(() => unidadDialog = val!),
                        ),
                      ),
                    ],
                  ),
                  if (verificando) ...[
                    const SizedBox(height: 15),
                    CircularProgressIndicator(color: accentGreen),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accentGreen),
                  onPressed: () async {
                    if (prodDialog != null && cantCtrl.text.isNotEmpty) {
                      setStateDialog(() => verificando = true);
                      double cantReq = double.tryParse(cantCtrl.text) ?? 0.0;
                      if (cantReq <= 0) {
                        setStateDialog(() => verificando = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("⚠️ Cantidad debe ser mayor a 0"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      var snap = await _firestore
                          .collection('Productos')
                          .where('nombre', isEqualTo: prodDialog)
                          .get();
                      double stockTotal = snap.docs.fold(
                        0,
                        (sum, doc) => sum + (doc['cantidad'] as num).toDouble(),
                      );

                      if (stockTotal <= 0) {
                        setStateDialog(() => verificando = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("❌ STOCK AGOTADO para $prodDialog"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (stockTotal < cantReq) {
                        setStateDialog(() => verificando = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "❌ STOCK INSUFICIENTE ($stockTotal disponible)",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        // <--- CORREGIDO: SE QUITÓ EL 'this.'
                        ingredientesSeleccionados.add({
                          'nombre': prodDialog,
                          'cantidad_usada': cantReq,
                          'unidad': unidadDialog,
                        });
                      });
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Añadir",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
