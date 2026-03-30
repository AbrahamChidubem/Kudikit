

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/address/nigeria_state.dart';


class AddressNotifier extends StateNotifier<AddressData> {
  AddressNotifier() : super(AddressData());

  void updateState(String value) {
    state = AddressData(
      state: value,
      city: state.city,
      lga: null, // Reset LGA when state changes
      landmark: state.landmark,
      streetName: state.streetName,
      houseNumber: state.houseNumber,
    );
  }

  void updateCity(String value) {
    state = AddressData(
      state: state.state,
      city: value,
      lga: state.lga,
      landmark: state.landmark,
      streetName: state.streetName,
      houseNumber: state.houseNumber,
    );
  }

  void updateLga(String value) {
    state = AddressData(
      state: state.state,
      city: state.city,
      lga: value,
      landmark: state.landmark,
      streetName: state.streetName,
      houseNumber: state.houseNumber,
    );
  }

  void updateLandmark(String value) {
    state = AddressData(
      state: state.state,
      city: state.city,
      lga: state.lga,
      landmark: value,
      streetName: state.streetName,
      houseNumber: state.houseNumber,
    );
  }

  void updateStreetName(String value) {
    state = AddressData(
      state: state.state,
      city: state.city,
      lga: state.lga,
      landmark: state.landmark,
      streetName: value,
      houseNumber: state.houseNumber,
    );
  }

  void updateHouseNumber(String value) {
    state = AddressData(
      state: state.state,
      city: state.city,
      lga: state.lga,
      landmark: state.landmark,
      streetName: state.streetName,
      houseNumber: value,
    );
  }

  void reset() {
    state = AddressData();
  }
}