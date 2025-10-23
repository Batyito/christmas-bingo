import 'dart:ui';

import 'package:christmas_bingo/models/bingo_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/pack.dart';

part 'game_service_part.dart';
part 'pack_service_part.dart';
part 'team_service_part.dart';
part 'settings_service_part.dart';
part 'family_service_part.dart';
part 'user_service_part.dart';

class FirestoreService {
  // Access Firestore lazily to avoid touching Firebase before initializeApp().
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  FirestoreService._privateConstructor();

  // Make the singleton lazy to prevent eager access during import time.
  static FirestoreService? _instance;
  static FirestoreService get instance =>
      _instance ??= FirestoreService._privateConstructor();
}
