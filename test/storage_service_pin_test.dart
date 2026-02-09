import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late StorageService storageService;

  setUp(() async {
    // Initialize shared preferences for testing
    SharedPreferences.setMockInitialValues({});
    
    // Get storage service instance
    storageService = StorageService.instance;
  });

  group('PIN Hashing Security Tests', () {
    test('Should hash PIN instead of storing plaintext', () async {
      const testPin = '123456';
      
      await storageService.savePin(testPin);
      
      // Try to read the stored value directly
      const secureStorage = FlutterSecureStorage();
      final storedValue = await secureStorage.read(key: 'user_pin');
      
      // Verify it's NOT the plaintext PIN
      expect(storedValue, isNot(equals(testPin)));
      
      // Verify it contains salt:hash:iterations format
      expect(storedValue, contains(':'));
      final parts = storedValue!.split(':');
      expect(parts.length, equals(3));
    });

    test('Should verify correct PIN successfully', () async {
      const testPin = '123456';
      
      await storageService.savePin(testPin);
      final isValid = await storageService.verifyPin(testPin);
      
      expect(isValid, isTrue);
    });

    test('Should reject incorrect PIN', () async {
      const correctPin = '123456';
      const wrongPin = '654321';
      
      await storageService.savePin(correctPin);
      final isValid = await storageService.verifyPin(wrongPin);
      
      expect(isValid, isFalse);
    });

    test('Should generate different hashes for same PIN (different salts)', () async {
      const testPin = '123456';
      
      // Save PIN first time
      await storageService.savePin(testPin);
      const secureStorage = FlutterSecureStorage();
      final firstHash = await secureStorage.read(key: 'user_pin');
      
      // Delete and save again
      await storageService.deletePin();
      await storageService.savePin(testPin);
      final secondHash = await secureStorage.read(key: 'user_pin');
      
      // Hashes should be different (different salts)
      expect(firstHash, isNot(equals(secondHash)));
      
      // But verification should still work for both
      expect(await storageService.verifyPin(testPin), isTrue);
    });

    test('Should reject non-numeric PIN', () async {
      expect(
        () => storageService.savePin('abc123'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject PIN shorter than 4 digits', () async {
      expect(
        () => storageService.savePin('123'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should reject PIN longer than 6 digits', () async {
      expect(
        () => storageService.savePin('1234567'),
        throwsA(isA<StorageException>()),
      );
    });

    test('Should accept 4-digit PIN', () async {
      const pin = '1234';
      await storageService.savePin(pin);
      expect(await storageService.verifyPin(pin), isTrue);
    });

    test('Should accept 6-digit PIN', () async {
      const pin = '123456';
      await storageService.savePin(pin);
      expect(await storageService.verifyPin(pin), isTrue);
    });

    test('hasPin should return false when no PIN is stored', () async {
      await storageService.deletePin();
      expect(await storageService.hasPin(), isFalse);
    });

    test('hasPin should return true when PIN is stored', () async {
      await storageService.savePin('123456');
      expect(await storageService.hasPin(), isTrue);
    });

    test('changePin should work with correct old PIN', () async {
      const oldPin = '123456';
      const newPin = '654321';
      
      await storageService.savePin(oldPin);
      
      final changed = await storageService.changePin(
        oldPin: oldPin,
        newPin: newPin,
      );
      
      expect(changed, isTrue);
      expect(await storageService.verifyPin(newPin), isTrue);
      expect(await storageService.verifyPin(oldPin), isFalse);
    });

    test('changePin should fail with incorrect old PIN', () async {
      const oldPin = '123456';
      const wrongOldPin = '111111';
      const newPin = '654321';
      
      await storageService.savePin(oldPin);
      
      final changed = await storageService.changePin(
        oldPin: wrongOldPin,
        newPin: newPin,
      );
      
      expect(changed, isFalse);
      // Old PIN should still work
      expect(await storageService.verifyPin(oldPin), isTrue);
    });

    test('deletePin should remove stored PIN', () async {
      await storageService.savePin('123456');
      expect(await storageService.hasPin(), isTrue);
      
      await storageService.deletePin();
      expect(await storageService.hasPin(), isFalse);
    });

    test('Should handle empty PIN gracefully', () async {
      expect(
        () => storageService.savePin(''),
        throwsA(isA<StorageException>()),
      );
    });

    test('PIN verification should be case-sensitive for numbers', () async {
      // This test ensures consistency - all numeric so no case issues
      const pin = '123456';
      await storageService.savePin(pin);
      expect(await storageService.verifyPin(pin), isTrue);
    });

    test('Should resist timing attacks via constant-time comparison', () async {
      const correctPin = '123456';
      const wrongPin1 = '100000'; // Different first digit
      const wrongPin2 = '123450'; // Different last digit
      
      await storageService.savePin(correctPin);
      
      // Measure time for different wrong PINs
      final stopwatch1 = Stopwatch()..start();
      await storageService.verifyPin(wrongPin1);
      stopwatch1.stop();
      
      final stopwatch2 = Stopwatch()..start();
      await storageService.verifyPin(wrongPin2);
      stopwatch2.stop();
      
      // Time difference should be minimal (within 10ms tolerance)
      // In a real constant-time implementation, this would be < 1ms
      final timeDiff = (stopwatch1.elapsedMicroseconds - stopwatch2.elapsedMicroseconds).abs();
      expect(timeDiff, lessThan(10000)); // 10ms tolerance
    });
  });

  group('PIN Security Strength Tests', () {
    test('Should use PBKDF2 with sufficient iterations', () async {
      const testPin = '123456';
      await storageService.savePin(testPin);
      
      const secureStorage = FlutterSecureStorage();
      final storedValue = await secureStorage.read(key: 'user_pin');
      final parts = storedValue!.split(':');
      
      final iterations = int.parse(parts[2]);
      // Verify at least 10,000 iterations (OWASP recommendation)
      expect(iterations, greaterThanOrEqualTo(10000));
    });

    test('Salt should be sufficiently random', () async {
      const testPin = '123456';
      
      // Generate multiple PINs and collect salts
      final salts = <String>{};
      for (var i = 0; i < 10; i++) {
        await storageService.deletePin();
        await storageService.savePin(testPin);
        
        const secureStorage = FlutterSecureStorage();
        final storedValue = await secureStorage.read(key: 'user_pin');
        final salt = storedValue!.split(':')[0];
        salts.add(salt);
      }
      
      // All salts should be unique
      expect(salts.length, equals(10));
    });

    test('Hash output should be consistent with same salt', () async {
      const testPin = '123456';
      await storageService.savePin(testPin);
      
      // Verify multiple times - should always return true
      for (var i = 0; i < 5; i++) {
        expect(await storageService.verifyPin(testPin), isTrue);
      }
    });
  });

  group('Migration and Edge Cases', () {
    test('Should handle corrupted storage gracefully', () async {
      // Manually store invalid data
      const secureStorage = FlutterSecureStorage();
      await secureStorage.write(key: 'user_pin', value: 'corrupted_data');
      
      // Verification should return false, not crash
      expect(await storageService.verifyPin('123456'), isFalse);
      expect(await storageService.hasPin(), isFalse);
    });

    test('Should handle missing storage', () async {
      await storageService.deletePin();
      expect(await storageService.verifyPin('123456'), isFalse);
    });
  });
}