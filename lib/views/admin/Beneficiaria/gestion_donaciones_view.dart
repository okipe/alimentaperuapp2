import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class GestionDonacionesView extends StatefulWidget {
  const GestionDonacionesView({super.key});

  @override
  State<GestionDonacionesView> createState() => _GestionDonacionesViewState();
}

class _GestionDonacionesViewState extends State<GestionDonacionesView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filtroUsuario = "";

  // Colores Premium Alimenta Perú
  final Color darkGreen = const Color(0xFF1A4D2E);
  final Color bgColor = const Color(0xFFF0F4F1);
  final Color accentGreen = const Color(0xFF2E7D52);

  // --- LÓGICA PROFESIONAL: VALIDAR Y SUMAR AL INVENTARIO ---
  Future<void> _validarDonacion(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final String producto = data['producto'] ?? 'Efectivo';
    final double cantidad = (data['cantidad'] ?? 0).toDouble();

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Cambiar el estado a "Completada"
        transaction.update(doc.reference, {'estado': 'Completada'});

        // 2. Si es producto, sumamos al stock de la tabla "Productos"
        if (data['tipo'] != 'Efectivo') {
          var prodQuery = await _firestore
              .collection('Productos')
              .where('nombre', isEqualTo: producto)
              .limit(1)
              .get();

          if (prodQuery.docs.isNotEmpty) {
            var prodRef = prodQuery.docs.first.reference;
            double stockActual = (prodQuery.docs.first['cantidad'] ?? 0)
                .toDouble();
            transaction.update(prodRef, {'cantidad': stockActual + cantidad});
          } else {
            // Si no existe, creamos el producto en el inventario
            DocumentReference nuevoProdRef = _firestore
                .collection('Productos')
                .doc();
            transaction.set(nuevoProdRef, {
              'nombre': producto,
              'cantidad': cantidad,
              'unidad': data['unidad'] ?? 'kg',
              'categoria': data['categoria'] ?? 'Otros',
              'fecha_vencimiento': data['fecha_vencimiento'],
            });
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "✅ Donación validada con éxito",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: accentGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al validar: $e");
    }
  }

  // --- WIDGET AUXILIAR: TRAER NOMBRE Y DNI DEL DONANTE ---
  Widget _buildDatosDonante(String? uid) {
    if (uid == null || uid.isEmpty) {
      return Text(
        "Donante: Desconocido",
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('usuarios').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            "Cargando datos...",
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String nombre = userData['nombre'] ?? '';
          String apellido = userData['apellido'] ?? '';
          String dni = userData['dni'] ?? 'Sin DNI';

          return Text(
            "$nombre $apellido\nDNI: $dni",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        // Protección contra RangeError si el usuario no existe en la BD pero dejó el UID
        String uidCorto = uid.length >= 8 ? uid.substring(0, 8) : uid;
        return Text(
          "Usuario no encontrado (UID: $uidCorto...)",
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: darkGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Control de Donaciones",
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            tabs: const [
              Tab(text: "PENDIENTES"),
              Tab(text: "HISTORIAL"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildListaPendientes(), _buildHistorial()],
        ),
      ),
    );
  }

  // --- PESTAÑA 1: PENDIENTES ---
  Widget _buildListaPendientes() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Donaciones')
          .where('estado', isEqualTo: 'Pendiente de Entrega')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty)
          return _buildEmptyState("No hay donaciones pendientes de recepción");

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            // Protección contra nulos (Evita el "null - 0 null")
            String nombreProd = data['producto'] ?? 'Donación';
            String cant = (data['cantidad'] ?? 0).toString();
            String unid = data['unidad'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                title: Text(
                  "$nombreProd - $cant $unid",
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: darkGreen,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatosDonante(data['usuario_id']),
                      const SizedBox(height: 5),
                      Text(
                        "Fecha: ${_formatDate(data['fecha_registro'])}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _validarDonacion(docs[index]),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    "VALIDAR",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- PESTAÑA 2: HISTORIAL Y FILTRO ---
  Widget _buildHistorial() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            onChanged: (v) => setState(() => _filtroUsuario = v),
            decoration: InputDecoration(
              hintText: "Buscar donante...",
              prefixIcon: Icon(Icons.search, color: darkGreen),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('Donaciones')
                .where('estado', isEqualTo: 'Completada')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              // Filtramos
              var docs = snapshot.data!.docs.where((d) {
                final id =
                    (d.data() as Map<String, dynamic>)['usuario_id'] ?? '';
                return id.toString().contains(_filtroUsuario);
              }).toList();

              // Ordenamos por fecha descendente
              docs.sort((a, b) {
                final dA =
                    (a.data() as Map<String, dynamic>)['fecha_registro']
                        as Timestamp?;
                final dB =
                    (b.data() as Map<String, dynamic>)['fecha_registro']
                        as Timestamp?;
                if (dA == null && dB == null) return 0;
                if (dA == null) return 1;
                if (dB == null) return -1;
                return dB.compareTo(dA);
              });

              if (docs.isEmpty)
                return _buildEmptyState("No se encontró historial");

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  bool esDinero = data['tipo'] == 'Efectivo';

                  // Evitar nulls
                  String prodTexto = esDinero
                      ? "S/ ${(data['monto'] ?? 0).toStringAsFixed(2)}"
                      : "${data['producto'] ?? 'Producto'} (${data['cantidad'] ?? 0} ${data['unidad'] ?? ''})";

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: esDinero ? Colors.blue[50] : Colors.orange[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          esDinero
                              ? Icons.payments_rounded
                              : Icons.inventory_2_rounded,
                          color: esDinero
                              ? Colors.blue[700]
                              : Colors.orange[700],
                        ),
                      ),
                      title: Text(
                        prodTexto,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: _buildDatosDonante(
                          data['usuario_id'],
                        ), // LLAMAMOS A LA FUNCIÓN DE NOMBRES
                      ),
                      trailing: Text(
                        _formatDate(data['fecha_registro']),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "---";
    return DateFormat('dd/MM/yyyy').format((timestamp as Timestamp).toDate());
  }

  Widget _buildEmptyState(String m) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_rounded, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 15),
        Text(
          m,
          style: GoogleFonts.dmSans(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
