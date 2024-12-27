import 'dart:ui';

import 'package:christmas_bingo/models/bingo_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/pack.dart';

part 'game_service_part.dart';
part 'pack_service_part.dart';
part 'team_service_part.dart';
part 'settings_service_part.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService._privateConstructor();

  static final FirestoreService instance = FirestoreService._privateConstructor();
}
