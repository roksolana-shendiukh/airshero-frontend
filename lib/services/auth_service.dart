import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  UserModel? _currentUser;
  String? _idToken;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get idToken => _idToken;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get needsPasswordChange =>
      _currentUser?.status == UserStatus.pendingPasswordChange;

  bool get isTempPasswordExpired =>
      _currentUser?.status == UserStatus.tempPasswordExpired;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Login failed');

      _idToken = await firebaseUser.getIdToken();
      final idTokenResult = await firebaseUser.getIdTokenResult();
      final claims = idTokenResult.claims ?? {};

      _currentUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: claims['firstName'] ?? '',
        lastName: claims['lastName'] ?? '',
        role: _parseRole(claims['role']),
        status: _parseStatus(claims['status']),
        airlineName: claims['airlineName'],     
        airlineLogoUrl: claims['airlineLogoUrl'],
        avatarUrl: claims['avatarUrl'] as String?,
        operationId: claims['operationId'] != null
          ? int.tryParse(claims['operationId'].toString())
          : null,
        createdAt: DateTime.now(),
      );

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSession() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return;

    await Future.delayed(const Duration(milliseconds: 500));
    _idToken = await firebaseUser.getIdToken(true);
    final idTokenResult = await firebaseUser.getIdTokenResult(true);
    final claims = idTokenResult.claims ?? {};

    _currentUser = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: claims['firstName'] ?? '',
      lastName: claims['lastName'] ?? '',
      role: _parseRole(claims['role']),
      status: _parseStatus(claims['status']),
      airlineName: claims['airlineName'],    
      airlineLogoUrl: claims['airlineLogoUrl'],
      avatarUrl: claims['avatarUrl'] as String?,
      operationId: claims['operationId'] != null
        ? int.tryParse(claims['operationId'].toString())
        : null,
      createdAt: DateTime.now(),
    );

    notifyListeners();
  }

  Future<String?> getToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    _idToken = await user.getIdToken();
    return _idToken;
  }


  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null || firebaseUser.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);

      _idToken = await firebaseUser.getIdToken(true);

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/change-password'),
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': newPassword}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        _errorMessage = data['detail'] is List
            ? (data['detail'] as List).first['msg']
            : data['detail'].toString();
        notifyListeners();
        return false;
      }

      await refreshSession();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _idToken = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return;

    try {
      _idToken = await firebaseUser.getIdToken();
      final idTokenResult = await firebaseUser.getIdTokenResult();
      final claims = idTokenResult.claims ?? {};

      _currentUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: claims['firstName'] ?? '',
        lastName: claims['lastName'] ?? '',
        role: _parseRole(claims['role']),
        status: _parseStatus(claims['status']),
        airlineName: claims['airlineName'],    
        airlineLogoUrl: claims['airlineLogoUrl'],
        avatarUrl: claims['avatarUrl'] as String?,
        operationId: claims['operationId'] != null
          ? int.tryParse(claims['operationId'].toString())
          : null,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      _currentUser = null;
    }

    notifyListeners();
  }
  
  UserRole _parseRole(dynamic role) {
    switch (role) {
      case 'salesAgent': return UserRole.salesAgent;
      case 'checkInAgent': return UserRole.checkInAgent;
      case 'flightOperator': return UserRole.flightOperator;
      case 'planningManager': return UserRole.planningManager;
      case 'systemAdmin': return UserRole.systemAdmin;
      default: return UserRole.salesAgent;
    }
  }

  UserStatus _parseStatus(dynamic status) {
    switch (status) {
      case 'active': return UserStatus.active;
      case 'locked': return UserStatus.locked;
      case 'pendingActivation': return UserStatus.pendingActivation;
      case 'pendingPasswordChange': return UserStatus.pendingPasswordChange;
      case 'tempPasswordExpired': return UserStatus.tempPasswordExpired;
      default: return UserStatus.pendingActivation;
    }
  }

  String _parseFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'User not found';
      case 'wrong-password': return 'Wrong password';
      case 'invalid-email': return 'Invalid email';
      case 'user-disabled': return 'Account is disabled';
      case 'too-many-requests': return 'Too many attempts. Try later';
      case 'invalid-credential': return 'Invalid email or password';
      case 'weak-password': return 'Password must be at least 6 characters';
      case 'requires-recent-login': return 'Please log in again to change password';
      default: return 'Error: $code';
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
        }),
      );
      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        _errorMessage = data['detail'] is List
            ? (data['detail'] as List).first['msg']
            : data['detail'].toString();
        notifyListeners();
        return false;
      }
      await refreshSession();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfilePhoto(List<int> fileBytes, String fileName) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/users/profile/photo'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(_mimeType(fileName)),
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      debugPrint('PHOTO RESPONSE: ${response.body}');
      if (response.statusCode != 200) return false;
      await refreshSession();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  String _mimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

}