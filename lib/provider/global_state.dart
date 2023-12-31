import 'package:flutter/foundation.dart';
import 'package:goltens_core/models/auth.dart';

class GlobalState with ChangeNotifier {
  UserResponse? _userResponse;

  UserResponse? get user => _userResponse;

  void setUserResponse(UserResponse? userResponse) {
    _userResponse = userResponse;
    notifyListeners();
  }
}
