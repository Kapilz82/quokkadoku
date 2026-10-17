import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:quokkadoku/levels.dart';
import 'package:quokkadoku/puzzle.dart';

void main() {
  test('generated puzzles are unique and valid', () {
    for (final n in [7, 8, 10]) {
      final p = Puzzle.generate(n, Random(1));
      expect(Puzzle.countSolutions(n, p.region), 1);
      expect(p.solution.toSet().length, n);
      for (var r = 1; r < n; r++) {
        expect((p.solution[r] - p.solution[r - 1]).abs() > 1, true);
      }
    }
  });

  test('stored levels are unique and load', () {
    for (final entry in levels.entries) {
      for (final s in entry.value) {
        final p = Puzzle.fromRegions(s);
        expect(p.n, entry.key);
        expect(Puzzle.countSolutions(p.n, p.region), 1);
      }
    }
  });
}
