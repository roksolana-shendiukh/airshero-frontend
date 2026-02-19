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
      'role': role.name,
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
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.salesAgent,
      ),
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

enum UserRole {
  salesAgent('Sales Agent'),
  checkInAgent('Check-in Agent'),
  flightOperator('Flight Operator'),
  planningManager('Planning Manager'),
  systemAdmin('System Admin');

  final String displayName;
  const UserRole(this.displayName);

  List<MenuItem> get menuItems {
    switch (this) {
      case UserRole.salesAgent:
        return [
          MenuItem(icon: Icons.search, title: 'Search Flights', route: '/sales/search'),
          MenuItem(icon: Icons.book_online, title: 'Create Booking', route: '/sales/bookings/create'),
          MenuItem(icon: Icons.list_alt, title: 'My Bookings', route: '/sales/bookings'),
          MenuItem(icon: Icons.payment, title: 'Payments', route: '/sales/payments'),
          MenuItem(icon: Icons.luggage, title: 'Baggage Options', route: '/sales/baggage'),
        ];
      case UserRole.checkInAgent:
        return [
          MenuItem(icon: Icons.qr_code_scanner, title: 'Scan Booking', route: '/checkin/scan'),
          MenuItem(icon: Icons.event_seat, title: 'Seat Assignment', route: '/checkin/seats'),
          MenuItem(icon: Icons.luggage, title: 'Baggage Check', route: '/checkin/baggage'),
          MenuItem(icon: Icons.receipt_long, title: 'Boarding Pass', route: '/checkin/boarding-pass'),
          MenuItem(icon: Icons.list, title: 'Check-in History', route: '/checkin/history'),
        ];
      case UserRole.flightOperator:
        return [
          MenuItem(icon: Icons.flight, title: 'Flight Status', route: '/operator/flights'),
          MenuItem(icon: Icons.flight_takeoff, title: 'Assign Aircraft', route: '/operator/aircraft'),
          MenuItem(icon: Icons.schedule, title: 'Update Times', route: '/operator/times'),
          MenuItem(icon: Icons.people, title: 'Passenger List', route: '/operator/passengers'),
          MenuItem(icon: Icons.cloud, title: 'Weather', route: '/operator/weather'),
        ];
      case UserRole.planningManager:
        return [
          MenuItem(icon: Icons.add_circle, title: 'Create Flight', route: '/planning/flights/create'),
          MenuItem(icon: Icons.flight, title: 'Manage Flights', route: '/planning/flights'),
          MenuItem(icon: Icons.attach_money, title: 'Pricing', route: '/planning/pricing'),
          MenuItem(icon: Icons.luggage, title: 'Baggage Tariffs', route: '/planning/baggage-tariffs'),
          MenuItem(icon: Icons.event_seat, title: 'Seat Allocation', route: '/planning/seats'),
          MenuItem(icon: Icons.analytics, title: 'Reports', route: '/planning/reports'),
        ];
      case UserRole.systemAdmin:
        return [
          MenuItem(icon: Icons.people, title: 'Users', route: '/admin/users'),
          MenuItem(icon: Icons.security, title: 'Roles', route: '/admin/roles'),
          MenuItem(icon: Icons.history, title: 'Audit Log', route: '/admin/audit'),
          MenuItem(icon: Icons.settings, title: 'Settings', route: '/admin/settings'),
        ];
    }
  }
}

enum UserStatus {
  pendingActivation('Pending'),
  active('Active'),
  locked('Locked');

  final String displayName;
  const UserStatus(this.displayName);
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