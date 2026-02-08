import 'package:flutter_test/flutter_test.dart';
import 'package:airshero_f/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const AirSheroApp());

    expect(find.text('AirShero F'), findsOneWidget);
    expect(find.text('Вітаємо в AirShero F'), findsOneWidget);
    expect(find.text('Знайти рейси'), findsOneWidget);
  });
}