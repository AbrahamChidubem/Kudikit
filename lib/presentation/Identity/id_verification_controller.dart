import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/constant/id_type.dart';
import 'package:kudipay/mock/mock_api_data.dart';
import 'package:kudipay/model/IDdocument/id_verification_state.dart';
import 'package:kudipay/presentation/Identity/verification_status.dart';
import 'package:flutter_riverpod/legacy.dart';
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

    // Use MockKycData so the verified name comes from the centralised mock,
    // not a literal string buried in the controller.
    final mockResponse = MockKycData.verifyIdentitySuccess(
      idNumber: idNumber,
      idType: state.idType.label,
    );

    state = state.copyWith(
      status: VerificationStatus.success,
      data: {
        'name': mockResponse['full_name'] as String,
        'idType': state.idType.label,
      },
    );
  }

  void reset() {
    state = IdVerificationState(idType: state.idType);
  }
}

