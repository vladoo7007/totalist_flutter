import 'package:flutter_test/flutter_test.dart';

import 'package:totalist_flutter/main.dart';

void main() {
  testWidgets('Totalist smoke test', (WidgetTester tester) async {
    // Palaist mūsu galveno widgetu
    await tester.pumpWidget(const TotalistApp());

    // Pārbaudām, ka virsraksts vai ekrāna saturs parādās
    expect(find.textContaining('Totalist'), findsOneWidget);
  });
}