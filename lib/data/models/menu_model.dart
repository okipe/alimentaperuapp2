class MenuModel {
  final String? id;
  final String entrada;
  final String segundo;
  final int raciones;
  final DateTime fecha;

  MenuModel({
    this.id,
    required this.entrada,
    required this.segundo,
    required this.raciones,
    required this.fecha,
  });

  // Convertir a JSON para enviar a Firestore
  Map<String, dynamic> toMap() {
    return {
      'entrada': entrada,
      'segundo': segundo,
      'raciones': raciones,
      'fecha': fecha,
    };
  }
}
