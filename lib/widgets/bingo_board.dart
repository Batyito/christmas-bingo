import 'package:flutter/material.dart';
import 'bingo_cell.dart';

class BingoBoard extends StatefulWidget {
  final List<List<String>> board; // Bingo board content
  final List<List<List<Map<String, dynamic>>>> marks; // Marks for each cell by team
  final Map<String, Color> teamColors; // Colors assigned to teams
  final Function(int row, int col) onMarkCell; // Callback for marking a cell
  final Function(int row, int col) onUnmarkCell; // Callback for unmarking a cell

  BingoBoard({
    required this.board,
    required this.marks,
    required this.teamColors,
    required this.onMarkCell,
    required this.onUnmarkCell,
  });

  @override
  _BingoBoardState createState() => _BingoBoardState();
}

class _BingoBoardState extends State<BingoBoard> {
  late Set<String> matchingCells; // Tracks cells that are part of a Bingo

  @override
  void initState() {
    super.initState();
    matchingCells = _getMatchingCells();
  }

  @override
  void didUpdateWidget(covariant BingoBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.marks != oldWidget.marks) {
      matchingCells = _getMatchingCells();
      setState(() {}); // Rebuild when marks change
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: EdgeInsets.all(20), // Allow panning outside bounds
      minScale: 0.5, // Minimum zoom-out scale
      maxScale: 2.5, // Maximum zoom-in scale
      child: Center(
        child: Container(
          padding: EdgeInsets.all(16.0), // Add padding around the board
          child: AspectRatio(
            aspectRatio: 1, // Ensure the board remains square
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(), // Prevent nested scrolling
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // Number of columns
                crossAxisSpacing: 4.0, // Space between cells horizontally
                mainAxisSpacing: 4.0, // Space between cells vertically
                childAspectRatio: 1, // Ensure cells are square
              ),
              itemCount: 25, // Total cells (5x5 grid)
              itemBuilder: (context, index) {
                int row = index ~/ 5; // Calculate row
                int col = index % 5; // Calculate column
                bool isMatching = matchingCells.contains('$row-$col'); // Check if the cell is part of a Bingo

                return GestureDetector(
                  onTap: () {
                    widget.onMarkCell(row, col); // Trigger the mark callback
                  },
                  onLongPress: () {
                    widget.onUnmarkCell(row, col); // Trigger the unmark callback
                  },

                  child: BingoCell(
                content: widget.board[row][col],
                  marks: widget.marks[row][col], // Pass marks for this cell
                  teamColors: widget.teamColors, // Pass team colors
                  isMatching: matchingCells.contains('$row-$col'), // Bingo status

                ),

                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Helper function to identify matching cells (part of a Bingo)
  Set<String> _getMatchingCells() {
    Set<String> matchingCells = {};

    // Check rows for Bingo
    for (int row = 0; row < 5; row++) {
      if (_isBingo(widget.marks[row])) {
        for (int col = 0; col < 5; col++) {
          matchingCells.add('$row-$col');
        }
      }
    }

    // Check columns for Bingo
    for (int col = 0; col < 5; col++) {
      if (_isBingo(List.generate(5, (row) => widget.marks[row][col]))) {
        for (int row = 0; row < 5; row++) {
          matchingCells.add('$row-$col');
        }
      }
    }

    // Check diagonals for Bingo
    if (_isBingo(List.generate(5, (i) => widget.marks[i][i]))) {
      for (int i = 0; i < 5; i++) {
        matchingCells.add('$i-$i');
      }
    }
    if (_isBingo(List.generate(5, (i) => widget.marks[i][4 - i]))) {
      for (int i = 0; i < 5; i++) {
        matchingCells.add('$i-${4 - i}');
      }
    }

    return matchingCells;
  }

  /// Check if a set of marks is a Bingo
  bool _isBingo(List<List<Map<String, dynamic>>> marks) {
    return marks.every((cellMarks) =>
        cellMarks.any((teamMark) => teamMark['marked'] == true));
  }

  void _showInfoDialog(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("bezár"),
            ),
          ],
        );
      },
    );
  }
}
