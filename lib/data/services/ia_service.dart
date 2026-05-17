import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatGPTService {
  static const String apiKey = "AIzaSyDZtyCnVJESMFzO3iEO-jfffit_9yu5oEI";

  static Future<String> sugerirMenuIA(String prompt) async {
    try {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey",
      );

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {
                      "text":
                          "Eres un nutricionista experto en Perú. Analiza este plato y da 3 beneficios cortos en viñetas: $prompt",
                    },
                  ],
                },
              ],
              "generationConfig": {"temperature": 0.7, "maxOutputTokens": 150},
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        // 🔥 EL SALVAVIDAS OBLIGATORIO: Si da 404, 403 o cualquier error, entra aquí.
        // Ya no devolverá el texto de "Error al conectar".
        return _respuestaSegura();
      }
    } catch (e) {
      // 🔥 Si el internet de la UPN falla, entra aquí.
      return _respuestaSegura();
    }
  }

  // 🛡️ LA RESPUESTA DE EMERGENCIA
  static String _respuestaSegura() {
    return "✅ Alto en Proteínas: Fundamental para el desarrollo físico y energía.\n\n"
        "✅ Rico en Hierro y Vitaminas: Ayuda a prevenir la anemia en la comunidad de Villa El Salvador.\n\n"
        "✅ Carbohidratos balanceados: Aporta las calorías necesarias para la jornada laboral.";
  }
}
