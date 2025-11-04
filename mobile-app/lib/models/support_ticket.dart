/// SupportTicket model
/// Represents a support message submitted by a user for admin review.

import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportTicketStatus { open, inProgress, closed }

extension SupportTicketStatusExt on SupportTicketStatus {
  String get label {
    switch (this) {
      case SupportTicketStatus.open:
        return 'open';
      case SupportTicketStatus.inProgress:
        return 'in_progress';
      case SupportTicketStatus.closed:
        return 'closed';
    }
  }

  static SupportTicketStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return SupportTicketStatus.inProgress;
      case 'closed':
        return SupportTicketStatus.closed;
      case 'open':
      default:
        return SupportTicketStatus.open;
    }
  }
}

class SupportTicket {
  SupportTicket({
    required this.ticketId,
    required this.userId,
    required this.userEmail,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastReplyFrom,
  });

  final String ticketId;
  final String userId;
  final String userEmail;
  final String subject;
  final String message;
  final SupportTicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastReplyFrom;

  factory SupportTicket.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SupportTicket(
      ticketId: data['ticketId']?.toString() ?? doc.id,
      userId: data['userId']?.toString() ?? '',
      userEmail: data['userEmail']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      status: SupportTicketStatusExt.fromString(data['status']?.toString()),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      lastReplyFrom: data['lastReplyFrom']?.toString(),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  SupportTicket copyWith({SupportTicketStatus? status}) {
    return SupportTicket(
      ticketId: ticketId,
      userId: userId,
      userEmail: userEmail,
      subject: subject,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastReplyFrom: lastReplyFrom,
    );
  }
}
