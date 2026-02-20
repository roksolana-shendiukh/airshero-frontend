import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? airlineName;
  final String? airlineLogoUrl;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
    this.airlineName,
    this.airlineLogoUrl,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'roleId': role.id,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'airlineName': airlineName,
      'airlineLogoUrl': airlineLogoUrl,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: UserRole.fromId(json['roleId'] as int),
      status: UserStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => UserStatus.pendingActivation,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      airlineName: json['airlineName'] as String?,
      airlineLogoUrl: json['airlineLogoUrl'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final String route;

  const MenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });
}

enum UserRole {
  salesAgent,
  checkInAgent,
  flightOperator,
  planningManager,
  systemAdmin;

  int get id {
    switch (this) {
      case UserRole.salesAgent: return 1;
      case UserRole.checkInAgent: return 2;
      case UserRole.flightOperator: return 3;
      case UserRole.planningManager: return 4;
      case UserRole.systemAdmin: return 5;
    }
  }

  static UserRole fromId(int id) {
    return UserRole.values.firstWhere(
      (r) => r.id == id,
      orElse: () => UserRole.salesAgent,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.salesAgent: return 'Sales Agent';
      case UserRole.checkInAgent: return 'Check-In Agent';
      case UserRole.flightOperator: return 'Flight Operator';
      case UserRole.planningManager: return 'Planning Manager';
      case UserRole.systemAdmin: return 'System Admin';
    }
  }

  List<MenuItem> get menuItems {
    switch (this) {
      case UserRole.salesAgent:
        return [
          const MenuItem(icon: Icons.book_outlined, title: 'Bookings', route: '/sales/bookings'),
        ];
      case UserRole.checkInAgent:
        return [
          const MenuItem(icon: Icons.how_to_reg_outlined, title: 'Check-In', route: '/checkin'),
        ];
      case UserRole.flightOperator:
        return [
          const MenuItem(icon: Icons.flight_outlined, title: 'Flights', route: '/operator/flights'),
        ];
      case UserRole.planningManager:
        return [
          const MenuItem(icon: Icons.calendar_month_outlined, title: 'Planning', route: '/planning'),
        ];
      case UserRole.systemAdmin:
        return [
          const MenuItem(icon: Icons.people_outline, title: 'Users', route: '/admin/users'),
        ];
    }
  }
}

enum UserStatus {
  pendingActivation('Pending'),
  pendingPasswordChange('Password Setup'),
  tempPasswordExpired('Expired'),
  active('Active'),
  locked('Locked');

  final String displayName;
  const UserStatus(this.displayName);
}

