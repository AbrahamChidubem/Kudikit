import 'package:kudipay/usecases/passcode_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasscodeNotifier extends StateNotifier<PasscodeState> {
  PasscodeNotifier()
      : super(
            PasscodeState(originalPasscode: '1234')); // Mock original passcode

  void addDigit(String digit) {
    if (state.enteredPasscode.length < 4) {
      final newPasscode = state.enteredPasscode + digit;
      state = state.copyWith(
        enteredPasscode: newPasscode,
        showError: false,
      );

      // Auto-validate when 4 digits are entered
      if (newPasscode.length == 4) {
        _validatePasscode(newPasscode);
      }
    }
  }

  void removeDigit() {
    if (state.enteredPasscode.isNotEmpty) {
      state = state.copyWith(
        enteredPasscode: state.enteredPasscode
            .substring(0, state.enteredPasscode.length - 1),
        showError: false,
      );
    }
  }

  void _validatePasscode(String passcode) {
    // Show loading state
    state = state.copyWith(isLoading: true);

    // Simulate API call or secure validation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (passcode == state.originalPasscode) {
        state = state.copyWith(
          isConfirmed: true,
          showError: false,
          isLoading: false,
        );
        // Navigate to next screen or show success
      } else {
        state = state.copyWith(
          showError: true,
          isLoading: false,
        );
        // Reset after showing error
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            state = state.copyWith(enteredPasscode: '', showError: false);
          }
        });
      }
    });
  }

  void reset() {
    state = PasscodeState(originalPasscode: state.originalPasscode);
  }

  bool get mounted => true; // Helper for cleanup
}
