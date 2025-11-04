/// SupportRepository
/// Handles CRUD operations for support tickets in Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/support_ticket.dart';
import 'firebase_service.dart';

class SupportRepository {
  SupportRepository._internal();

  static final SupportRepository _instance = SupportRepository._internal();
  factory SupportRepository() => _instance;

  final FirebaseService _firebaseService = FirebaseService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseService.firestore.collection('supportTickets');

  Future<void> createTicket({
    required String subject,
    required String message,
  }) async {
    if (!_firebaseService.isFirestoreAvailable) {
      throw Exception('Support messaging is unavailable offline.');
    }

    final user = _firebaseService.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to contact support.');
    }

    final docRef = _collection.doc();
    await docRef.set({
      'ticketId': docRef.id,
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'subject': subject.trim(),
      'message': message.trim(),
      'status': SupportTicketStatus.open.label,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastReplyFrom': 'user',
    });
  }

  Stream<List<SupportTicket>> listenToTickets({bool includeClosed = true}) {
    if (!_firebaseService.isFirestoreAvailable) {
      return const Stream.empty();
    }

    Query<Map<String, dynamic>> query = _collection.orderBy('createdAt', descending: true);
    if (!includeClosed) {
      query = query.where('status', isNotEqualTo: SupportTicketStatus.closed.label);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => SupportTicket.fromSnapshot(doc))
          .toList(),
    );
  }

  Stream<SupportTicket?> watchTicket(String ticketId) {
    if (!_firebaseService.isFirestoreAvailable) {
      return const Stream.empty();
    }

    return _collection.doc(ticketId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SupportTicket.fromSnapshot(doc);
    });
  }

  Future<void> updateStatus(String ticketId, SupportTicketStatus status) async {
    if (!_firebaseService.isFirestoreAvailable) {
      throw Exception('Firestore is not available');
    }

    await _collection.doc(ticketId).update({
      'status': status.label,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastReplyFrom': 'admin',
    });
  }

  Future<SupportTicket?> getTicket(String ticketId) async {
    if (!_firebaseService.isFirestoreAvailable) {
      return null;
    }

    final snapshot = await _collection.doc(ticketId).get();
    if (!snapshot.exists) return null;
    return SupportTicket.fromSnapshot(snapshot);
  }
}
