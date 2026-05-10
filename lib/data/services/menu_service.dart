import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> guardarMenu(MenuModel menu) async {
    try {
      await _db.collection('Menus').add(menu.toMap());
    } catch (e) {
      throw Exception("Error al guardar el menú: $e");
    }
  }
}
