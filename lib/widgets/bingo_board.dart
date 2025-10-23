import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
// 'material.dart' already exports animation APIs; remove unused extra imports.
import 'package:flutter_fireworks/fireworks_controller.dart';
import 'package:flutter_fireworks/fireworks_display.dart';
import '../services/firestore/firestore_service.dart';
import 'bingo_cell.dart';

class BingoBoard extends StatefulWidget {
  final String gameId; // Game ID
  final List<List<String>> board; // Bingo board content
  final List<List<List<Map<String, dynamic>>>>
      marks; // Marks for each cell by team
  final Map<String, Color> teamColors; // Team colors
  final Function(int row, int col) onMarkCell; // Callback for marking a cell
  final Function(int row, int col)
      onUnmarkCell; // Callback for unmarking a cell
  final String teamId; // Current team ID

  const BingoBoard({
    super.key,
    required this.gameId,
    required this.board,
    required this.marks,
    required this.teamColors,
    required this.onMarkCell,
    required this.onUnmarkCell,
    required this.teamId,
  });

  @override
  BingoBoardState createState() => BingoBoardState();
}

class BingoBoardState extends State<BingoBoard>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService.instance;
  late Set<String> matchingCells;
  Set<String> _previousMatchingCells = {}; // Track previously matched cells
  late ConfettiController _confettiControllerTopLeft;
  late ConfettiController _confettiControllerTopRight;
  late ConfettiController _confettiControllerBottomLeft;
  late ConfettiController _confettiControllerBottomRight;
  late FireworksController _fireworksController;
  late AnimationController _bingoAnimationController;
  late Animation<double> _bingoAnimationScale;
  bool _isWinnerMarked = false; // Ensure winner is marked only once
  bool _showBingoText = false; // Control for showing BINGO text
  bool _showFireworks = false; // Control for showing fireworks

  @override
  void initState() {
    super.initState();
    matchingCells = _getMatchingCellsForTeam(widget.teamId);
    _previousMatchingCells = {
      ...matchingCells
    }; // Initialize with current bingos

    // Initialize confetti controllers for multiple sources
    _confettiControllerTopLeft =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiControllerTopRight =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiControllerBottomLeft =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiControllerBottomRight =
        ConfettiController(duration: const Duration(seconds: 3));

    _fireworksController = FireworksController(
      colors: [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.orange
      ],
      minExplosionDuration: 0.5,
      maxExplosionDuration: 3.5,
      minParticleCount: 125,
      maxParticleCount: 275,
      fadeOutDuration: 0.4,
    );
    // Initialize animation for BINGO text
    _bingoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _bingoAnimationScale = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
          parent: _bingoAnimationController, curve: Curves.easeInOut),
    );

    _initializeGameStatus();
  }

  @override
  void didUpdateWidget(covariant BingoBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.marks != oldWidget.marks || widget.teamId != oldWidget.teamId) {
      final newMatchingCells = _getMatchingCellsForTeam(widget.teamId);

      // Check if a new bingo is achieved
      final isNewBingo = newMatchingCells.isNotEmpty &&
          !_previousMatchingCells.containsAll(newMatchingCells);

      if (isNewBingo) {
        _triggerBingoCelebration();
        _markWinnerIfNone(
            widget.teamId); // Mark the winner if not already marked
      }

      _previousMatchingCells = {...newMatchingCells};
      matchingCells = newMatchingCells;

      setState(() {});
    }
  }

  Future<void> _initializeGameStatus() async {
    try {
      final gameSnapshot = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();
      if (gameSnapshot.exists) {
        final data = gameSnapshot.data();
        if (data != null && data['status'] == 'vége') {
          _isWinnerMarked = true;
          if (kDebugMode) {
            print("Game already won by team: ${data['winner']}");
          }
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("Error fetching game status: $error");
      }
    }
  }

  void _triggerBingoCelebration() {
    // Trigger confetti from all sources
    _confettiControllerTopLeft.play();
    _confettiControllerTopRight.play();
    _confettiControllerBottomLeft.play();
    _confettiControllerBottomRight.play();

    _fireworksController.fireMultipleRockets(
        minRockets: 5,
        maxRockets: 20,
        launchWindow: const Duration(milliseconds: 600));

    // Trigger BINGO text animation
    setState(() {
      _showBingoText = true;
      _showFireworks = true;
    });
    _bingoAnimationController.forward().then((_) {
      // Hide the BINGO text after animation
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _showBingoText = false;
        });
        _bingoAnimationController.reset();
      });
    });
  }

  /// Check if there's no winner and mark the current team as the winner
  Future<void> _markWinnerIfNone(String teamId) async {
    if (_isWinnerMarked) return; // Avoid duplicate marking
    try {
      await _firestoreService.updateGameStatus(widget.gameId, teamId);
      _isWinnerMarked = true; // Ensure winner is only marked once
      if (kDebugMode) {
        print("Winner marked: $teamId");
      }
    } catch (error) {
      if (kDebugMode) {
        print("Error marking winner: $error");
      }
    }
  }

  @override
  void dispose() {
    // Dispose all confetti controllers
    _confettiControllerTopLeft.dispose();
    _confettiControllerTopRight.dispose();
    _confettiControllerBottomLeft.dispose();
    _confettiControllerBottomRight.dispose();
    _bingoAnimationController.dispose(); // Dispose animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 2.5,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                    childAspectRatio: 1,
                  ),
                  itemCount: 25,
                  itemBuilder: (context, index) {
                    int row = index ~/ 5;
                    int col = index % 5;
                    bool isMatching = matchingCells.contains('$row-$col');

                    return GestureDetector(
                      onTap: () {
                        widget.onMarkCell(row, col);
                      },
                      onLongPress: () {
                        widget.onUnmarkCell(row, col);
                      },
                      child: BingoCell(
                        content: widget.board[row][col],
                        marks: widget.marks[row][col],
                        teamColors: widget.teamColors,
                        isMatching: isMatching,
                        currentTeamId: widget.teamId,
                        teamOrder: widget.teamColors.keys.toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // Confetti effects from all corners
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiControllerTopLeft,
            blastDirection: 0.785, // Diagonal direction
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            shouldLoop: false,
            colors: [Colors.red, Colors.green, Colors.blue, Colors.yellow],
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiControllerTopRight,
            blastDirection: 2.356, // Diagonal direction
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            shouldLoop: false,
            colors: [Colors.red, Colors.green, Colors.blue, Colors.yellow],
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: ConfettiWidget(
            confettiController: _confettiControllerBottomLeft,
            blastDirection: -0.785, // Diagonal direction
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            shouldLoop: false,
            colors: [Colors.red, Colors.green, Colors.blue, Colors.yellow],
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: ConfettiWidget(
            confettiController: _confettiControllerBottomRight,
            blastDirection: -2.356, // Diagonal direction
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            shouldLoop: false,
            colors: [Colors.red, Colors.green, Colors.blue, Colors.yellow],
          ),
        ),
        if (_showFireworks)
          FireworksDisplay(
            controller: _fireworksController,
          ),
        // Animated BINGO Text
        if (_showBingoText)
          ScaleTransition(
            scale: _bingoAnimationScale,
            child: Text(
              "BINGO!",
              style: TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                shadows: [
                  Shadow(
                    offset: Offset(3, 3),
                    blurRadius: 5,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Set<String> _getMatchingCellsForTeam(String teamId) {
    Set<String> matchingCells = {};

    for (int row = 0; row < 5; row++) {
      if (_isBingo(widget.marks[row], teamId)) {
        for (int col = 0; col < 5; col++) {
          matchingCells.add('$row-$col');
        }
      }
    }

    for (int col = 0; col < 5; col++) {
      if (_isBingo(List.generate(5, (row) => widget.marks[row][col]), teamId)) {
        for (int row = 0; row < 5; row++) {
          matchingCells.add('$row-$col');
        }
      }
    }

    if (_isBingo(List.generate(5, (i) => widget.marks[i][i]), teamId)) {
      for (int i = 0; i < 5; i++) {
        matchingCells.add('$i-$i');
      }
    }

    if (_isBingo(List.generate(5, (i) => widget.marks[i][4 - i]), teamId)) {
      for (int i = 0; i < 5; i++) {
        matchingCells.add('$i-${4 - i}');
      }
    }

    return matchingCells;
  }

  bool _isBingo(List<List<Map<String, dynamic>>> marks, String teamId) {
    return marks.every((cellMarks) => cellMarks
        .any((mark) => mark['marked'] == true && mark['teamId'] == teamId));
  }
}
