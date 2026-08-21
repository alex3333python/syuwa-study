import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_syuwa/main.dart';

void main() {
  testWidgets('shows language selection on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('ことばをえらぼう'), findsOneWidget);
    expect(find.text('Português'), findsOneWidget);
    expect(find.text('Tagalog'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
  });
}
