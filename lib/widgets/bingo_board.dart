import 'package:flutter/material.dart';
import 'bingo_cell.dart';

class BingoBoard extends StatefulWidget {
  final List<List<String>> board; // Bingo board content
  final List<List<List<Map<String, dynamic>>>> marks; // Marks for each cell by team
  final Map<String, Color> teamColors; // Team colors
  final Function(int row, int col) onMarkCell; // Callback for marking a cell
  final Function(int row, int col) onUnmarkCell; // Callback for unmarking a cell
  final String teamId; // Current team ID

  const BingoBoard({
    super.key,
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

class BingoBoardState extends State<BingoBoard> {
  late Set<String> matchingCells;

  @override
  void initState() {
    super.initState();
    matchingCells = _getMatchingCellsForTeam(widget.teamId);
  }

  @override
  void didUpdateWidget(covariant BingoBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.marks != oldWidget.marks || widget.teamId != oldWidget.teamId) {
      matchingCells = _getMatchingCellsForTeam(widget.teamId);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
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
    return marks.every((cellMarks) =>
        cellMarks.any((mark) => mark['marked'] == true && mark['teamId'] == teamId));
  }
}
