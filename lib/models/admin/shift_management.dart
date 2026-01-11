import 'package:flutter/material.dart';

class ShiftManagement {
  final int id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isActive;
  final String? description;
  final int? locationId; // Location assigned to this shift

  ShiftManagement({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    this.description,
    this.locationId,
  });

  factory ShiftManagement.fromJson(Map<String, dynamic> json) {
    return ShiftManagement(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      startTime: _parseTimeSpan(json['startTime']),
      endTime: _parseTimeSpan(json['endTime']),
      isActive: json['isActive'] ?? true,
      description: json['description'],
      locationId: json['locationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': _formatTimeSpan(startTime),
      'endTime': _formatTimeSpan(endTime),
      'isActive': isActive,
      'description': description,
      'locationId': locationId,
    };
  }

  // Helper: Parse TimeSpan string from backend (e.g., "08:00:00")
  static TimeOfDay _parseTimeSpan(dynamic timeSpan) {
    if (timeSpan == null) return const TimeOfDay(hour: 0, minute: 0);

    final parts = timeSpan.toString().split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  // Helper: Format TimeOfDay to TimeSpan string for backend
  static String _formatTimeSpan(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  // Helper: Get formatted time string
  String get startTimeFormatted {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get endTimeFormatted {
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper: Get duration in hours
  double get durationHours {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    var endMinutes = endTime.hour * 60 + endTime.minute;

    // Handle overnight shifts
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    return (endMinutes - startMinutes) / 60.0;
  }

  // Helper: Get color based on shift type
  Color get shiftColor {
    final hour = startTime.hour;
    if (hour >= 6 && hour < 12) {
      return Colors.orange; // Morning
    } else if (hour >= 12 && hour < 18) {
      return Colors.blue; // Afternoon
    } else {
      return Colors.indigo; // Night
    }
  }

  // Helper: Get shift type name
  String get shiftTypeName {
    final hour = startTime.hour;
    if (hour >= 6 && hour < 12) {
      return 'Ca sáng';
    } else if (hour >= 12 && hour < 18) {
      return 'Ca chiều';
    } else {
      return 'Ca tối';
    }
  }

  // Copy with method for easy updates
  ShiftManagement copyWith({
    int? id,
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isActive,
    String? description,
  }) {
    return ShiftManagement(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }
}
