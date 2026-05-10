import 'package:flutter/material.dart';
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
  final TextEditingController _racionesController = TextEditingController();

  String? _cocineraSeleccionada;
  String? _platoSeleccionado;
  List<Map<String, dynamic>> insumosParaMenu = [];
  bool _guardando = false;

  // Colores consistentes con la marca
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  // --- LÓGICA DE GUARDADO ULTRA-RÁPIDA ---
  Future<void> _guardarMenu() async {
    double rac = double.tryParse(_racionesController.text) ?? 0;

    if (_platoSeleccionado == null ||
        _cocineraSeleccionada == null ||
        rac <= 0 ||
        insumosParaMenu.isEmpty) {
      _notificar("⚠️ Datos incompletos", Colors.orange);
      return;
    }

    // FEEDBACK INSTANTÁNEO: Cerramos procesos visuales de inmediato
    _notificar("🚀 Registro enviado...", darkGreen);
    final insumosTemporales = List<Map<String, dynamic>>.from(insumosParaMenu);
    final plato = _platoSeleccionado;
    final cocinera = _cocineraSeleccionada;

    _limpiarForm(); // Limpiamos la UI de inmediato para que el usuario pueda seguir

    try {
      WriteBatch batch = _firestore.batch();
      DateTime ahora = DateTime.now();

      for (var insumo in insumosTemporales) {
        double pendiente = insumo['cantidad'];

        // Consulta simplificada para evitar latencia de índices
        var snap = await _firestore
            .collection('Productos')
            .where('nombre', isEqualTo: insumo['producto'])
            .get();

        // Filtrado rápido en memoria (Dart)
        var lotes = snap.docs
            .where((doc) => (doc['cantidad'] as num) > 0)
            .toList();
        lotes.sort((a, b) {
          var fA = a.data().containsKey('fecha_vencimiento')
              ? a['fecha_vencimiento'] as Timestamp
              : Timestamp.now();
          var fB = b.data().containsKey('fecha_vencimiento')
              ? b['fecha_vencimiento'] as Timestamp
              : Timestamp.now();
          return fA.compareTo(fB);
        });

        for (var doc in lotes) {
          if (pendiente <= 0) break;
          double stockActual = (doc['cantidad'] as num).toDouble();
          double aDescontar = stockActual >= pendiente
              ? pendiente
              : stockActual;
          pendiente -= aDescontar;
          batch.update(doc.reference, {'cantidad': stockActual - aDescontar});
        }

        // Registro de Movimiento (Salida)
        batch.set(_firestore.collection('Movimientos').doc(), {
          'tipo': 'SALIDA_MENU',
          'fecha': Timestamp.fromDate(ahora),
          'producto': insumo['producto'],
          'cantidad_utilizada': insumo['cantidad'],
          'unidad': insumo['unidad'],
          'menu': plato,
          'cocinera': cocinera,
        });
      }

      // Registro Maestro del Menú
      batch.set(_firestore.collection('Menues').doc(), {
        'plato': plato,
        'cocinera': cocinera,
        'raciones': rac,
        'fecha': Timestamp.fromDate(ahora),
        'insumos': insumosTemporales,
      });

      await batch.commit(); // Ejecución en segundo plano
    } catch (e) {
      _notificar("❌ Error en segundo plano: $e", Colors.red);
    }
  }

  void _limpiarForm() {
    _racionesController.clear();
    setState(() {
      _cocineraSeleccionada = null;
      _platoSeleccionado = null;
      insumosParaMenu.clear();
      _guardando = false;
    });
  }

  void _abrirDialogoInsumos() {
    String? cat;
    String? prod;
    String unit = 'kg';
    TextEditingController cantC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
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
              _buildDrop(
                "Categoría",
                cat,
                ['Abarrotes', 'Menestras', 'Verduras', 'Carnes'],
                (v) => setS(() {
                  cat = v;
                  prod = null;
                }),
              ),
              const SizedBox(height: 12),
              if (cat != null)
                _buildDrop("Producto", prod, [
                  'Arroz',
                  'Lenteja',
                  'Pollo',
                ], (v) => setS(() => prod = v)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: cantC,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle("Cant.", Icons.scale_rounded),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDrop("Unid", unit, [
                      'kg',
                      'lt',
                      'unid',
                    ], (v) => setS(() => unit = v!)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
              onPressed: () {
                double val = double.tryParse(cantC.text) ?? 0;
                if (prod != null && val > 0) {
                  setState(() {
                    int idx = insumosParaMenu.indexWhere(
                      (i) => i['producto'] == prod,
                    );
                    if (idx != -1)
                      insumosParaMenu[idx]['cantidad'] += val;
                    else
                      insumosParaMenu.add({
                        'producto': prod,
                        'cantidad': val,
                        'unidad': unit,
                      });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Añadir",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 25),
                  _buildHistorial(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 60, bottom: 25, left: 15, right: 15),
    decoration: BoxDecoration(
      color: darkGreen,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
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
            "REGISTRO DE MENÚ",
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

  Widget _buildFormCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("RESPONSABLE"),
        _buildCocineraStream(),
        const SizedBox(height: 15),
        _buildLabel("PLATO PRINCIPAL"),
        _buildDrop("Plato", _platoSeleccionado, [
          "Arroz con pollo",
          "Lentejas",
          "Estofado",
        ], (v) => setState(() => _platoSeleccionado = v)),
        const SizedBox(height: 15),
        _buildLabel("RACIONES"),
        TextField(
          controller: _racionesController,
          keyboardType: TextInputType.number,
          decoration: _inputStyle("Ej: 50", Icons.restaurant),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel("INSUMOS"),
            IconButton(
              onPressed: _abrirDialogoInsumos,
              icon: Icon(Icons.add_circle, color: accentGreen),
            ),
          ],
        ),
        ...insumosParaMenu.map(
          (i) => ListTile(
            title: Text(
              i['producto'],
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "-${i['cantidad']} ${i['unidad']}",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => setState(() => insumosParaMenu.remove(i)),
            ),
            dense: true,
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _guardando ? null : _guardarMenu,
            child: _guardando
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "GUARDAR REGISTRO",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _buildHistorial() => StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('Menues')
        .orderBy('fecha', descending: true)
        .limit(3)
        .snapshots(),
    builder: (context, snap) {
      if (!snap.hasData) return const SizedBox();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ÚLTIMOS REGISTROS",
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 10),
          ...snap.data!.docs.map(
            (d) => Card(
              child: ListTile(
                title: Text(d['plato'] ?? '-'),
                subtitle: Text(d['cocinera'] ?? '-'),
                trailing: Text("${d['raciones']} rac."),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _buildLabel(String t) => Text(
    t,
    style: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: accentGreen,
    ),
  );
  InputDecoration _inputStyle(String h, IconData i) => InputDecoration(
    prefixIcon: Icon(i, size: 18),
    hintText: h,
    filled: true,
    fillColor: bgColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
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
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: v,
        hint: Text(h),
        items: i
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onC,
      ),
    ),
  );
  Widget _buildCocineraStream() => StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection('cocineras').snapshots(),
    builder: (context, snap) {
      if (!snap.hasData) return const LinearProgressIndicator();
      var list = snap.data!.docs.map((d) => d['nombre'].toString()).toList();
      return _buildDrop(
        "Responsable",
        _cocineraSeleccionada,
        list,
        (v) => setState(() => _cocineraSeleccionada = v),
      );
    },
  );

  void _notificar(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: c,
          duration: const Duration(
            milliseconds: 1200,
          ), // Notificación más rápida
          behavior: SnackBarBehavior.floating,
        ),
      );
}
