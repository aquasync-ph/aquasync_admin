import 'package:flutter_test/flutter_test.dart';
import 'package:aquasync_admin/main.dart';

void main() {
  testWidgets('AquaSyncAdminApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AquaSyncAdminApp());
    expect(find.byType(AquaSyncAdminApp), findsOneWidget);
  });
}
