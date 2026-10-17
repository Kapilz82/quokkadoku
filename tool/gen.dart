// ignore_for_file: avoid_print
// Vorberechnung: dart run tool/gen.dart <n> <anzahl>  -> Zeilen mit Gebiets-Strings
import 'dart:math';
import 'package:quokkadoku/puzzle.dart';

void main(List<String> args) {
  final n = int.parse(args[0]), count = int.parse(args[1]);
  for (var level = 1; level <= count; level++) {
    print(Puzzle.generate(n, Random(level * 7919 + n)).toRegions());
  }
}
