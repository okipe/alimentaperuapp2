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
  final TextEditingController _racionesController = TextEditingController();

  String? _cocineraSeleccionada;
  String? _platoSeleccionado;
  DateTime _fechaMenu = DateTime.now();
  List<Map<String, dynamic>> insumosParaMenu = [];
  bool _guardando = false;

  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  // --- LÓGICA DE GUARDADO (SIN CAMBIOS EN TU LÓGICA FIFO) ---
  Future<void> _guardarMenu() async {
    final double? raciones = double.tryParse(_racionesController.text);
    if (raciones == null || raciones <= 0) {
      _notificar("⚠️ Las raciones deben ser un número positivo", Colors.orange);
      return;
    }
    if (_platoSeleccionado == null ||
        _cocineraSeleccionada == null ||
        insumosParaMenu.isEmpty) {
      _notificar("⚠️ Datos incompletos", Colors.orange);
      return;
    }

    setState(() => _guardando = true);
    DateTime ahora = DateTime.now();

    try {
      WriteBatch batch = _firestore.batch();
      for (var insumo in insumosParaMenu) {
        double pendiente = insumo['cantidad'];
        var snap = await _firestore
            .collection('Productos')
            .where('nombre', isEqualTo: insumo['producto'])
            .get();
        var lotesValidos = snap.docs.where((doc) {
          double stock = (doc['cantidad'] as num).toDouble();
          DateTime venc = doc.data().containsKey('fecha_vencimiento')
              ? (doc['fecha_vencimiento'] as Timestamp).toDate()
              : ahora.add(const Duration(days: 365));
          return stock > 0 && venc.isAfter(ahora);
        }).toList();

        double totalDisponible = lotesValidos.fold(
          0.0,
          (s, d) => s + (d['cantidad'] as num).toDouble(),
        );
        if (totalDisponible < pendiente) {
          _notificar(
            "❌ Stock insuficiente o vencido para: ${insumo['producto']}",
            Colors.red,
          );
          setState(() => _guardando = false);
          return;
        }

        lotesValidos.sort((a, b) {
          var f1 = a.data().containsKey('fecha_vencimiento')
              ? a['fecha_vencimiento'] as Timestamp
              : Timestamp.now();
          var f2 = b.data().containsKey('fecha_vencimiento')
              ? b['fecha_vencimiento'] as Timestamp
              : Timestamp.now();
          return f1.compareTo(f2);
        });

        for (var doc in lotesValidos) {
          if (pendiente <= 0) break;
          double stockActual = (doc['cantidad'] as num).toDouble();
          double descontar = stockActual >= pendiente ? pendiente : stockActual;
          pendiente -= descontar;
          batch.update(doc.reference, {'cantidad': stockActual - descontar});
        }
      }

      batch.set(_firestore.collection('Menues').doc(), {
        'plato': _platoSeleccionado,
        'cocinera': _cocineraSeleccionada,
        'raciones': raciones,
        'fecha': Timestamp.fromDate(_fechaMenu),
        'insumos': insumosParaMenu,
      });

      await batch.commit();
      if (mounted) {
        _notificar("✅ Menú registrado correctamente", darkGreen);
        _limpiarForm();
      }
    } catch (e) {
      if (mounted) _notificar("❌ Error al guardar", Colors.red);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // --- DIÁLOGO DE INSUMOS ACTUALIZADO (PERMITE EDITAR) ---
  void _abrirDialogoInsumos({Map<String, dynamic>? editInsumo, int? index}) {
    String? cat;
    String? prod = editInsumo?['producto'];
    String unit = editInsumo?['unidad'] ?? 'kg';
    TextEditingController cantC = TextEditingController(
      text: editInsumo?['cantidad']?.toString() ?? '',
    );

    final Map<String, List<String>> productosPorCategoria = {
      'Abarrotes': ['Arroz', 'Fideos', 'Aceite', 'Azúcar', 'Sal', 'Huevos'],
      'Menestras': ['Lenteja', 'Frijol', 'Arveja partida', 'Garbanzo'],
      'Verduras': ['Cebolla', 'Tomate', 'Papa', 'Zanahoria', 'Ajo'],
      'Carnes': ['Pollo', 'Res', 'Pescado', 'Cerdo'],
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Row(
            children: [
              Icon(
                editInsumo == null ? Icons.add_box_outlined : Icons.edit_note,
                color: darkGreen,
              ),
              const SizedBox(width: 10),
              Text(
                editInsumo == null ? "Nuevo Insumo" : "Editar Insumo",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Solo mostramos selección de producto si es nuevo
              if (editInsumo == null) ...[
                _buildDropWithIcon(
                  "Categoría",
                  Icons.category_outlined,
                  cat,
                  productosPorCategoria.keys.toList(),
                  (v) => setS(() {
                    cat = v;
                    prod = null;
                  }),
                ),
                const SizedBox(height: 15),
                if (cat != null)
                  _buildDropWithIcon(
                    "Producto",
                    Icons.shopping_basket_outlined,
                    prod,
                    productosPorCategoria[cat]!,
                    (v) => setS(() => prod = v),
                  ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: accentGreen, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Editando: ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(prod!),
                    ],
                  ),
                ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: cantC,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'(^\d*\.?\d*)'),
                        ),
                      ],
                      decoration: _inputStyle("Cantidad", Icons.numbers),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDrop("Unid", unit, [
                      'kg',
                      'lt',
                      'unid',
                      'gr',
                    ], (v) => setS(() => unit = v!)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar", style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                double? val = double.tryParse(cantC.text);
                if (val == null || val <= 0) {
                  _notificar("⚠️ Ingrese cantidad válida", Colors.orange);
                  return;
                }
                if (prod == null) {
                  _notificar("⚠️ Elija producto", Colors.orange);
                  return;
                }
                setState(() {
                  if (index != null) {
                    // EDITAR EXISTENTE
                    insumosParaMenu[index] = {
                      'producto': prod,
                      'cantidad': val,
                      'unidad': unit,
                    };
                  } else {
                    // AÑADIR NUEVO
                    insumosParaMenu.add({
                      'producto': prod,
                      'cantidad': val,
                      'unidad': unit,
                    });
                  }
                });
                Navigator.pop(context);
              },
              child: Text(
                editInsumo == null ? "Añadir" : "Guardar",
                style: const TextStyle(color: Colors.white),
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
                  _buildHistorialDesplegable(),
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
    padding: const EdgeInsets.only(top: 60, bottom: 25, left: 10, right: 10),
    decoration: BoxDecoration(
      color: darkGreen,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
        Text(
          "REGISTRO DE MENÚ",
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
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
        _buildLabel("FECHA DE SERVICIO"),
        _buildDatePicker(),
        const SizedBox(height: 15),
        _buildLabel("RESPONSABLE Y PLATO"),
        _buildCocineraStream(),
        const SizedBox(height: 10),
        _buildDrop(
          "Plato del día",
          _platoSeleccionado,
          ["Arroz con pollo", "Lentejas", "Estofado", "Sopa de Mote"],
          (v) => setState(() => _platoSeleccionado = v),
        ),
        const SizedBox(height: 15),
        _buildLabel("CANTIDAD DE RACIONES"),
        TextField(
          controller: _racionesController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)')),
          ],
          decoration: _inputStyle("Personas", Icons.groups_outlined),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel("INSUMOS A UTILIZAR"),
            IconButton(
              onPressed: () => _abrirDialogoInsumos(),
              icon: Icon(Icons.add_circle, color: accentGreen, size: 30),
            ),
          ],
        ),
        _buildListaInsumos(), // Aquí está la lista con opción de editar
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
                    "GUARDAR MENÚ",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _buildListaInsumos() => Column(
    children: insumosParaMenu
        .asMap()
        .entries
        .map(
          (entry) => Card(
            elevation: 0,
            color: bgColor.withOpacity(0.5),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.flatware, color: accentGreen),
              title: Text(
                entry.value['producto'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${entry.value['cantidad']} ${entry.value['unidad']}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BOTÓN EDITAR
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blue,
                      size: 20,
                    ),
                    onPressed: () => _abrirDialogoInsumos(
                      editInsumo: entry.value,
                      index: entry.key,
                    ),
                  ),
                  // BOTÓN ELIMINAR
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => insumosParaMenu.removeAt(entry.key)),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );

  // --- COMPONENTES AUXILIARES ---
  Widget _buildDatePicker() => InkWell(
    onTap: () async {
      DateTime? p = await showDatePicker(
        context: context,
        initialDate: _fechaMenu,
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
      );
      if (p != null) setState(() => _fechaMenu = p);
    },
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('dd/MM/yyyy').format(_fechaMenu)),
          Icon(Icons.calendar_month, color: accentGreen),
        ],
      ),
    ),
  );

  Widget _buildDropWithIcon(
    String h,
    IconData icon,
    String? v,
    List<String> i,
    Function(String?) onC,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: accentGreen),
        const SizedBox(width: 10),
        Expanded(
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
        ),
      ],
    ),
  );

  void _notificar(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating,
        ),
      );
  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      t,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: accentGreen,
      ),
    ),
  );
  InputDecoration _inputStyle(String h, IconData i) => InputDecoration(
    prefixIcon: Icon(i, size: 18, color: accentGreen),
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

  Widget _buildHistorialDesplegable() => StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('Menues')
        .orderBy('fecha', descending: true)
        .limit(5)
        .snapshots(),
    builder: (context, snap) {
      if (!snap.hasData) return const SizedBox();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "REGISTROS RECIENTES",
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 10),
          ...snap.data!.docs.map(
            (d) => Card(
              child: ExpansionTile(
                leading: const Icon(Icons.history),
                title: Text(
                  d['plato'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat(
                    'dd/MM/yyyy',
                  ).format((d['fecha'] as Timestamp).toDate()),
                ),
                children: (d['insumos'] as List)
                    .map(
                      (i) => ListTile(
                        dense: true,
                        title: Text(i['producto']),
                        trailing: Text("${i['cantidad']} ${i['unidad']}"),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      );
    },
  );

  void _limpiarForm() {
    _racionesController.clear();
    setState(() {
      _cocineraSeleccionada = null;
      _platoSeleccionado = null;
      insumosParaMenu.clear();
    });
  }
}
