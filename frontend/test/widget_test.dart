// Prueba básica de humo para la app de Flutter.
//
// Para interactuar con un widget en tus pruebas, usa el WidgetTester
// del paquete flutter_test. Por ejemplo, puedes simular toques y scroll.
// También puedes usar WidgetTester para buscar widgets hijos en el árbol
// de widgets, leer texto y verificar que las propiedades sean correctas.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fronted/main.dart';

void main() {
  testWidgets('La app arranca en la pantalla de acceso', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // Construimos la app y disparamos un frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verificamos que la pantalla de Login se muestre primero.
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('FreshClean'), findsOneWidget);
  });
}
