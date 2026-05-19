// ignore_for_file: spell_checker
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite for ffi (for desktop/test environment)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper.instance;
    });

    test('Test Register and Login', () async {
      final username = 'testuser';
      final password = 'testpassword';

      // Register
      final result = await dbHelper.registerUser(username, password);
      expect(result, isNot(-1));

      // Login Success
      final loginSuccess = await dbHelper.loginUser(username, password);
      expect(loginSuccess, true);

      // Login Failure (Wrong password)
      final loginFail = await dbHelper.loginUser(username, 'wrongpassword');
      expect(loginFail, false);
      
      // Register existing user should fail
      final secondRegister = await dbHelper.registerUser(username, 'newpassword');
      expect(secondRegister, -1);
    });
  });
}
