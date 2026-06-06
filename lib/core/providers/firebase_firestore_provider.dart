import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (Firebase.apps.isEmpty) {
    return null;
  }
  return FirebaseFirestore.instance;
});
