import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/constant/id_type.dart';
import 'package:kudipay/model/id&document/id_verification_state.dart';
import 'package:kudipay/presentation/Identity/verification_status.dart';

final idVerificationProvider =
    StateNotifierProvider<IdVerificationController, IdVerificationState>(
  (ref) => IdVerificationController(),
);

class IdVerificationController
    extends StateNotifier<IdVerificationState> {
  IdVerificationController()
      : super(const IdVerificationState(idType: IdType.bvn));

  void changeIdType(IdType type) {
    state = state.copyWith(
      idType: type,
      status: VerificationStatus.input,
      error: null,
      data: null,
    );
  }

  Future<void> verifyId(String idNumber) async {
    if (idNumber.length != 11) {
      state = state.copyWith(
        status: VerificationStatus.error,
        error: '${state.idType.label} must be 11 digits',
      );
      return;
    }

    state = state.copyWith(
      status: VerificationStatus.loading,
      error: null,
    );

    await Future.delayed(const Duration(seconds: 2));

    // simulate response
    state = state.copyWith(
      status: VerificationStatus.success,
      data: {
        'name': 'Chidubem Abraham',
        'idType': state.idType.label,
      },
    );
  }

  void reset() {
    state = IdVerificationState(idType: state.idType);
  }
}

