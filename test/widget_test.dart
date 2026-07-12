import 'package:coptic_chiurch_finder/models/church_model.dart';
import 'package:coptic_chiurch_finder/providers/church_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Church serializes to and from JSON', () {
    final church = Church.fromJson({
      'id': 'church_1',
      'name': 'Test Church',
      'address': 'Cairo, Egypt',
      'latitude': 30,
      'longitude': 31.25,
      'description': 'Test description',
      'imageUrl': 'assets/images/Logo.png',
    });

    expect(church.latitude, 30.0);
    expect(church.toJson()['name'], 'Test Church');
  });

  test(
    'ChurchProvider loads local churches and finds the nearest one',
    () async {
      final provider = ChurchProvider();

      await provider.loadChurches();
      provider.calculateNearestChurch(30.0053, 31.2302);

      expect(provider.churches.length, greaterThanOrEqualTo(15));
      expect(provider.nearestChurch?.id, 'hanging_church_cairo');
    },
  );
}
