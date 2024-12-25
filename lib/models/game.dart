import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final List<String> bingoPool;
  final int boardSize;
  final String status;
  final String? winner;
  final DateTime createdAt;

  Game({
    required this.id,
    required this.bingoPool,
    required this.boardSize,
    required this.status,
    this.winner,
    required this.createdAt,
  });

  factory Game.fromFirestore(Map<String, dynamic> data) {
    return Game(
      id: data['id'],
      bingoPool: List<String>.from(data['bingoPool']),
      boardSize: data['boardSize'],
      status: data['status'],
      winner: data['winner'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
