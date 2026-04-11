import 'package:flutter_test/flutter_test.dart';
import 'package:airshero_f/main.dart';
import 'package:airshero_f/services/auth_service.dart';
import 'package:airshero_f/services/checkin_service.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(AirSheroApp(
      authService: AuthService(),
      checkinService:    CheckInService(),
      initialLightTheme: true,
    ));

    expect(find.text('AirShero F'), findsOneWidget);
  });
}