import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CloudSyncService {
  CloudSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _appStateDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('app_state')
        .doc('main');
  }

  Future<Map<String, dynamic>?> loadAppData(String uid) async {
    final snapshot = await _appStateDoc(uid).get();
    final docData = snapshot.data();

    if (!snapshot.exists || docData == null) return null;

    final rawData = docData['data'];
    if (rawData is! Map) return null;

    return Map<String, dynamic>.from(rawData);
  }

  Future<void> saveAppData(String uid, Map<String, dynamic> data) async {
    // Legacy sync: whole app state in one document
    await _appStateDoc(uid).set(
      {
        'updatedAt': FieldValue.serverTimestamp(),
        'data': data,
      },
      SetOptions(merge: true),
    );

    // Migration dual-write: Save habits to a separate subcollection
    // to prevent the 1MB Firestore document limit in the future.
    try {
      if (data.containsKey('habits') && data['habits'] is List) {
        final batch = _firestore.batch();
        final habitsRef = _firestore.collection('users').doc(uid).collection('habits');

        for (final habitRaw in data['habits']) {
          if (habitRaw is Map<String, dynamic> && habitRaw['id'] != null) {
            final docRef = habitsRef.doc(habitRaw['id'].toString());
            batch.set(docRef, habitRaw, SetOptions(merge: true));
          }
        }
        await batch.commit();
      }
    } catch (e) {
      // Catch errors so the legacy flow isn't interrupted
      debugPrint('Migration dual-write failed: $e');
    }
  }

  Future<void> deleteAppData(String uid) async {
    await _appStateDoc(uid).delete();
  }
}
