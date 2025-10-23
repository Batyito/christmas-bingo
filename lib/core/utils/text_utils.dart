/// Text utilities used across the app for fuzzy matching and normalization.
///
/// Centralizing these avoids duplicate private helpers across screens.

String normalizeText(String s) {
  final onlyLetters = s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áéíóöőúüű\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return onlyLetters;
}

bool isCloseText(String a, String b) {
  if (a == b) return true;
  if (a.contains(b) || b.contains(a)) return true;
  return levDistance(a, b) <= 2; // small edit distance threshold
}

int levDistance(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final m =
      List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) m[i][0] = i;
  for (var j = 0; j <= b.length; j++) m[0][j] = j;
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      m[i][j] = [
        m[i - 1][j] + 1,
        m[i][j - 1] + 1,
        m[i - 1][j - 1] + cost,
      ].reduce((v, e) => v < e ? v : e);
    }
  }
  return m[a.length][b.length];
}
