import 'package:flutter/foundation.dart';

enum EventCategory { ACADEMIC, SOCIAL, WORKSHOP, NETWORKING, CAREER, ALUMINI }

class EventModel {
  final int? id;
  final String title;
  final String? description;
  final String? location;

  /// Backend sends LocalDate as "yyyy-MM-dd" (e.g. "2026-03-06")
  final String eventDate;

  /// Backend sends LocalTime as "HH:mm:ss" (e.g. "14:30:00") — NOT a full datetime
  final String? startTime;
  final String? endTime;

  final int? organizer;
  final String? organizerName;
  final EventCategory category;
  final int? maxAttendees;
  final DateTime? createdAt;
  final int? attendeeCount;

  const EventModel({
    this.id,
    required this.title,
    this.description,
    this.location,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.organizer,
    this.organizerName,
    required this.category,
    this.maxAttendees,
    this.createdAt,
    this.attendeeCount,
  });

  /// Whether the event is in the future. Parses only the date portion.
  bool get isUpcoming {
    try {
      return DateTime.parse(eventDate).isAfter(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .subtract(const Duration(days: 1)),
      );
    } catch (_) {
      return false;
    }
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      // LocalDate arrives as "yyyy-MM-dd" — store as-is
      eventDate: json['eventDate'] as String,
      // LocalTime arrives as "HH:mm:ss" — store as-is, do NOT parse as DateTime
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      organizer: json['organizer'] != null
          ? (json['organizer'] as num).toInt()
          : null,
      organizerName: json['organizerName'] as String?,
      category: EventCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
      ),
      maxAttendees: json['maxAttendees'] != null
          ? (json['maxAttendees'] as num).toInt()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      attendeeCount: json['attendeeCount'] != null
          ? (json['attendeeCount'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
        // Send back in the same format the backend expects
        'eventDate': eventDate,
        'startTime': startTime,
        'endTime': endTime,
        'category': category.toString().split('.').last,
        'maxAttendees': maxAttendees,
      };
}