import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  // MOCK: Hardcoded current user (для демо)
  UserModel? _currentUser = UserModel(
    id: '1',
    email: 'admin@airshero.com',
    firstName: 'Admin',
    lastName: 'User',
    role: UserRole.systemAdmin, // ← Змінюйте це для тестування різних ролей
    status: UserStatus.active,
    createdAt: DateTime.now(),
  );

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // MOCK: Зміна користувача (для тестування)
  void switchUser(UserRole role) {
    _currentUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: '${role.name}@airshero.com',
      firstName: role.displayName.split(' ')[0],
      lastName: role.displayName.split(' ').length > 1 ? role.displayName.split(' ')[1] : 'User',
      role: role,
      status: UserStatus.active,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}