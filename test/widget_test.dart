import 'package:flutter_test/flutter_test.dart';
import 'package:max_food/core/config/env.dart';

void main() {
  test('Env constants are defined', () {
    expect(Env.supabaseUrl, isA<String>());
    expect(Env.supabaseAnonKey, isA<String>());
  });
}
