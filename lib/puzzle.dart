import 'dart:math';

/// Star-Battle-Regeln: n x n Gitter, n Gebiete, genau ein Quokka pro Zeile,
/// Spalte und Gebiet, keine diagonale Berührung.
class Puzzle {
  final int n;
  final List<List<int>> region; // region[r][c] = Gebiets-Id 0..n-1
  final List<int> solution; // solution[r] = Spalte des Quokkas in Zeile r

  Puzzle._(this.n, this.region, this.solution);

  static const sizes = [6, 7, 8, 9, 10];

  static String difficulty(int n) =>
      n <= 7 ? 'Leicht' : n <= 9 ? 'Mittel' : 'Schwer';

  /// Keine Mini-Gebiete, sonst ist der Quokka geschenkt.
  static const minRegion = 3;

  /// Deterministisch pro Runde und Größe, damit Runde 7 immer Runde 7 ist.
  static Puzzle forLevel(int level, int n) =>
      generate(n, Random(level * 7919 + n));

  /// Felder, die ein Quokka bei (r, c) blockiert: Zeile, Spalte, Gebiet,
  /// diagonale Nachbarn.
  Iterable<(int, int)> blockedBy(int r, int c) sync* {
    for (var rr = 0; rr < n; rr++) {
      for (var cc = 0; cc < n; cc++) {
        if (rr == r && cc == c) continue;
        if (rr == r ||
            cc == c ||
            region[rr][cc] == region[r][c] ||
            ((rr - r).abs() == 1 && (cc - c).abs() == 1)) {
          yield (rr, cc);
        }
      }
    }
  }

  static Puzzle generate(int n, Random rng) {
    while (true) {
      final sol = _randomSolution(n, rng);
      if (sol == null) continue;
      final reg = _growRegions(n, sol, rng);
      if (reg == null) continue;
      if (countSolutions(n, reg, limit: 2) == 1) return Puzzle._(n, reg, sol);
    }
  }

  static bool _ok(List<int> cols, int r, int c) {
    for (var i = 0; i < r; i++) {
      if (cols[i] == c) return false;
      if (i == r - 1 && (cols[i] - c).abs() <= 1) return false;
    }
    return true;
  }

  static List<int>? _randomSolution(int n, Random rng) {
    final cols = List.filled(n, -1);
    bool place(int r) {
      if (r == n) return true;
      final order = List.generate(n, (i) => i)..shuffle(rng);
      for (final c in order) {
        if (_ok(cols, r, c)) {
          cols[r] = c;
          if (place(r + 1)) return true;
        }
      }
      return false;
    }

    return place(0) ? cols : null;
  }

  static List<List<int>>? _growRegions(int n, List<int> sol, Random rng) {
    final reg = List.generate(n, (_) => List.filled(n, -1));
    for (var r = 0; r < n; r++) {
      reg[r][sol[r]] = r;
    }
    var free = n * n - n;
    const d = [(0, 1), (1, 0), (0, -1), (-1, 0)];
    final size = List.filled(n, 1);
    var stuck = 0;
    while (free > 0) {
      // Erst jedes Gebiet auf Mindestgröße, dann große bevorzugen
      // (ungleiche Gebiete -> eher eindeutig).
      var id = rng.nextInt(n);
      final small = [for (var i = 0; i < n; i++) if (size[i] < minRegion) i];
      if (small.isNotEmpty) {
        id = small[rng.nextInt(small.length)];
      } else {
        for (var t = 0; t < 2; t++) {
          final other = rng.nextInt(n);
          if (size[other] > size[id]) id = other;
        }
      }
      final cands = <(int, int)>[];
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (reg[r][c] != id) continue;
          for (final (dr, dc) in d) {
            final rr = r + dr, cc = c + dc;
            if (rr >= 0 && rr < n && cc >= 0 && cc < n && reg[rr][cc] == -1) {
              cands.add((rr, cc));
            }
          }
        }
      }
      if (cands.isEmpty) {
        // ponytail: bei Sackgasse neu würfeln statt reparieren
        if (++stuck > n * n) return null;
        continue;
      }
      stuck = 0;
      final (r, c) = cands[rng.nextInt(cands.length)];
      reg[r][c] = id;
      size[id]++;
      free--;
    }
    return size.any((s) => s < minRegion) ? null : reg;
  }

  static int countSolutions(int n, List<List<int>> reg, {int limit = 2}) {
    final cols = List.filled(n, -1);
    final usedReg = List.filled(n, false);
    var count = 0;
    void go(int r) {
      if (count >= limit) return;
      if (r == n) {
        count++;
        return;
      }
      for (var c = 0; c < n; c++) {
        final id = reg[r][c];
        if (usedReg[id] || !_ok(cols, r, c)) continue;
        cols[r] = c;
        usedReg[id] = true;
        go(r + 1);
        cols[r] = -1;
        usedReg[id] = false;
      }
    }

    go(0);
    return count;
  }

  bool isQuokka(int r, int c) => solution[r] == c;
}
