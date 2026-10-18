import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alex.dart';
import 'puzzle.dart';
import 'quokka.dart';

void main() => runApp(const App());

const _cream = Color(0xFFFFF6E9);
const _brown = Color(0xFF6D4C41);
const _card = Colors.white;

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Quokkadoku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: _brown,
          scaffoldBackgroundColor: _cream,
          useMaterial3: true,
        ),
        home: const GamePage(),
      );
}

// Kräftige, freundliche Kachelfarben; eine pro Gebiet.
const _regionColors = [
  Color(0xFFF48FB1), // rosa
  Color(0xFFFFD54F), // gelb
  Color(0xFF81D4FA), // hellblau
  Color(0xFFB39DDB), // lavendel
  Color(0xFFAED581), // grün
  Color(0xFFFFAB91), // pfirsich
  Color(0xFF80CBC4), // mint
  Color(0xFFE57373), // korallrot
  Color(0xFFBCAAA4), // sand
  Color(0xFF7986CB), // indigo
];

enum Mark { none, cross, quokka }

class _Float {
  final int r, c, points, id;
  _Float(this.r, this.c, this.points, this.id);
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int level = 1;
  int size = 7;
  int score = 0;
  int seed = 0; // einmal pro Gerät gewürfelt, mischt die Rätsel-Reihenfolge
  bool autoCross = false; // Luisa setzt ihre ✕ lieber selbst
  late Puzzle puzzle;
  late List<List<Mark>> marks;
  int hearts = 3;
  bool loaded = false;
  (int, int)? wrong; // Feld, das gerade rot aufblitzt
  final floats = <_Float>[];
  int floatId = 0;
  int sparkles = 0; // > 0 während der Gewinn-Konfetti
  int bannersClosed = 0; // pro Runde; nach 3 ist Ruhe

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      size = p.getInt('size') ?? 7;
      level = p.getInt('level_$size') ?? 1;
      score = p.getInt('score') ?? 0;
      autoCross = p.getBool('autoCross') ?? false;
      seed = p.getInt('seed') ?? DateTime.now().millisecondsSinceEpoch % 100000;
      p.setInt('seed', seed);
      _start();
    });
  }

  Future<void> _menu(int n) async {
    final p = await SharedPreferences.getInstance();
    if (n == -1) {
      setState(() => autoCross = !autoCross);
      await p.setBool('autoCross', autoCross);
      return;
    }
    if (n == -2) {
      final earned = {
        for (final s in eggSizes)
          if (p.getBool('egg_$s') ?? false) s
      };
      if (mounted) await showVouchers(context, earned);
      return;
    }
    await p.setInt('size', n);
    size = n;
    level = p.getInt('level_$size') ?? 1;
    _start();
  }

  Future<void> _start() async {
    if (!Puzzle.isStored(level, size)) {
      // Fallback-Generator kann dauern: erst Ladebildschirm zeichnen lassen.
      setState(() => loaded = false);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    puzzle = Puzzle.forLevel(level, size, seed: seed);
    marks = List.generate(puzzle.n, (_) => List.filled(puzzle.n, Mark.none));
    hearts = 3;
    wrong = null;
    bannersClosed = 0;
    if (mounted) setState(() => loaded = true);
  }

  int get placed =>
      marks.expand((r) => r).where((m) => m == Mark.quokka).length;

  (int, int)? _lastTap;
  DateTime _lastTapAt = DateTime(0);

  /// ✕ sofort setzen (kein 300-ms-Warten von onDoubleTap); zweiter Tipp
  /// auf dasselbe Feld innerhalb 300 ms = Quokka setzen.
  void _tap(int r, int c) {
    if (marks[r][c] == Mark.quokka) return;
    final now = DateTime.now();
    final isDouble = _lastTap == (r, c) &&
        now.difference(_lastTapAt) < const Duration(milliseconds: 300);
    _lastTap = (r, c);
    _lastTapAt = now;
    setState(() =>
        marks[r][c] = marks[r][c] == Mark.cross ? Mark.none : Mark.cross);
    if (isDouble) {
      _lastTap = null;
      _doubleTap(r, c);
    }
  }

  Future<void> _addPoints(int r, int c, int points) async {
    score += points;
    floats.add(_Float(r, c, points, floatId++));
    (await SharedPreferences.getInstance()).setInt('score', score);
  }

  void _place(int r, int c, {int points = 0}) {
    setState(() {
      marks[r][c] = Mark.quokka;
      if (autoCross) {
        for (final (rr, cc) in puzzle.blockedBy(r, c)) {
          if (marks[rr][cc] == Mark.none) marks[rr][cc] = Mark.cross;
        }
      }
      if (points > 0) _addPoints(r, c, points);
    });
    if (placed == puzzle.n) _won();
  }

  void _doubleTap(int r, int c) {
    if (marks[r][c] == Mark.quokka) return;
    if (puzzle.isQuokka(r, c)) {
      _place(r, c, points: 10 * puzzle.n);
    } else {
      setState(() {
        marks[r][c] = Mark.none; // das ✕ vom ersten Tipp zurücknehmen
        hearts--;
        wrong = (r, c);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => wrong = null);
      });
      if (hearts == 0) _lost();
    }
  }

  /// Deckt einen noch fehlenden Quokka auf (ohne Punkte).
  void _hint() {
    for (var r = 0; r < puzzle.n; r++) {
      final c = puzzle.solution[r];
      if (marks[r][c] != Mark.quokka) return _place(r, c);
    }
  }

  Future<void> _dialog(String title, String body, String button) => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: _cream,
          title: Text(title,
              style:
                  const TextStyle(color: _brown, fontWeight: FontWeight.w900)),
          content: Text(body, style: const TextStyle(fontSize: 16)),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context), child: Text(button))
          ],
        ),
      );

  void _rules() => _dialog(
        'So geht Quokkadoku',
        '🏡 In jedem farbigen Gebiet wohnt genau ein Quokka.\n\n'
        '↔️ In jeder Zeile und jeder Spalte sitzt genau eines.\n\n'
        '🚫 Quokkas berühren sich nie, auch nicht diagonal.\n\n'
        '👆 Tippen setzt ein ✕ auf Felder, wo keins sitzen kann.\n'
        '👆👆 Doppeltippen setzt ein Quokka. Falsch = ein Herz weg, '
        'drei Fehler = Runde von vorn.\n\n'
        '💡 Die Glühbirne deckt ein Quokka auf (ohne Punkte).\n'
        '⚙️ Im Menü: Feldgröße und ob ✕ automatisch gesetzt werden.',
        'Alles klar',
      );

  Future<void> _won() async {
    final bonus = hearts * 20 * puzzle.n;
    setState(() {
      sparkles = 12;
      _addPoints(puzzle.n ~/ 2, puzzle.n ~/ 2, bonus);
    });
    level++;
    final p = await SharedPreferences.getInstance();
    await p.setInt('level_$size', level);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _dialog('Alle Quokkas zuhause! 🎉',
        'Herz-Bonus +$bonus\nWeiter zu Runde $level', 'Los');
    if (luisaBuild &&
        level == 10 &&
        eggSizes.contains(size) &&
        !(p.getBool('egg_$size') ?? false)) {
      await p.setBool('egg_$size', true);
      if (mounted) await showEgg(context, size);
    }
    sparkles = 0;
    _start();
  }

  Future<void> _lost() async {
    await _dialog('Keine Herzen mehr 💔', 'Nochmal versuchen?', 'Nochmal');
    _start();
  }

  // --- UI-Bausteine -------------------------------------------------------

  Widget _pill(Widget child, {Color color = _card}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _ruleChip(String text) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEBDCC8)),
          ),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: _brown)),
        ),
      );

  Widget _tile(int r, int c, int n) {
    final base = _regionColors[puzzle.region[r][c] % _regionColors.length];
    final mark = marks[r][c];
    final isWrong = wrong == (r, c);
    // Eliminierte Felder werden dunkler, wie bei den Katzen.
    final color = isWrong
        ? const Color(0xFFEF5350)
        : mark == Mark.cross
            ? Color.lerp(base, _brown, 0.35)!
            : base;
    final edge = Color.lerp(color, Colors.black, 0.18)!;
    return GestureDetector(
      onTap: () => _tap(r, c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(n > 8 ? 7 : 10),
          border: Border(bottom: BorderSide(color: edge, width: 3)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: switch (mark) {
            Mark.none => const SizedBox.expand(key: ValueKey(0)),
            Mark.cross => Center(
                key: const ValueKey(1),
                child: Text('✕',
                    style: TextStyle(
                      fontSize: 190 / n,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                            color: Color(0x55000000),
                            blurRadius: 3,
                            offset: Offset(0, 1))
                      ],
                    )),
              ),
            Mark.quokka => Container(
                key: const ValueKey(2),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: const Quokka(),
              ),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: LoadingQuokka()));
    }
    final n = puzzle.n;
    const gap = 4.0;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Kopfzeile: Info · Titel · Tipp · Menü
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Spielanleitung',
                    icon: const Icon(Icons.info_outline, color: _brown),
                    onPressed: _rules,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Runde $level',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: _brown)),
                        Text('${Puzzle.difficulty(n)} · $n×$n',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFA1887F))),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tipp: einen Quokka aufdecken',
                    icon: const Icon(Icons.lightbulb_outline, color: _brown),
                    onPressed: _hint,
                  ),
                  PopupMenuButton<int>(
                    tooltip: 'Einstellungen',
                    icon: const Icon(Icons.settings, color: _brown),
                    initialValue: size,
                    onSelected: _menu,
                    itemBuilder: (_) => [
                      for (final n in Puzzle.sizes)
                        PopupMenuItem(
                            value: n,
                            child: Text('$n×$n · ${Puzzle.difficulty(n)}')),
                      const PopupMenuDivider(),
                      CheckedPopupMenuItem(
                          value: -1,
                          checked: autoCross,
                          child: const Text('✕ automatisch setzen')),
                      if (luisaBuild)
                        const PopupMenuItem(
                            value: -2, child: Text('🍣 Meine Gutscheine')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Zähler · Herzen · Punkte
            Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _pill(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 26, height: 26, child: Quokka()),
                    const SizedBox(width: 6),
                    Text('$placed',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF43A047))),
                    Text('/$n',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _brown)),
                  ],
                )),
                _pill(AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text('❤️' * hearts + '🤍' * (3 - hearts),
                      key: ValueKey(hearts),
                      style: const TextStyle(fontSize: 18)),
                )),
                _pill(
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: score),
                    duration: const Duration(milliseconds: 600),
                    builder: (_, v, child) => Text('⭐ $v',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _brown)),
                  ),
                  color: const Color(0xFFFFE0A3),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Gebiets-Leiste: ein Kästchen pro Gebiet
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < n; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _regionColors[i % _regionColors.length],
                      borderRadius: BorderRadius.circular(7),
                      border: Border(
                          bottom: BorderSide(
                              color: Color.lerp(
                                  _regionColors[i % _regionColors.length],
                                  Colors.black,
                                  0.18)!,
                              width: 2)),
                    ),
                    child: marks[i][puzzle.solution[i]] == Mark.quokka
                        ? const Padding(
                            padding: EdgeInsets.all(2), child: Quokka())
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Regel-Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                _ruleChip('1 Quokka pro Farbe'),
                _ruleChip('1 pro Zeile & Spalte'),
                _ruleChip('Nie berühren, auch nicht diagonal'),
              ]),
            ),
            // Brett auf weißer Karte
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 14,
                            offset: Offset(0, 6))
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (_, box) {
                        final cell = (box.maxWidth + gap) / n;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: n,
                                      mainAxisSpacing: gap,
                                      crossAxisSpacing: gap),
                              itemCount: n * n,
                              itemBuilder: (_, i) => _tile(i ~/ n, i % n, n),
                            ),
                            for (final f in floats)
                              Positioned(
                                key: ValueKey('f${f.id}'),
                                left: f.c * cell,
                                top: f.r * cell,
                                width: cell,
                                child: Center(
                                  child: FloatingPoints(
                                    points: f.points,
                                    onDone: () =>
                                        setState(() => floats.remove(f)),
                                  ),
                                ),
                              ),
                            for (var i = 0; i < sparkles; i++)
                              Positioned(
                                key: ValueKey('s$i'),
                                left: box.maxWidth * (i + 0.5) / sparkles,
                                top: box.maxWidth / 2,
                                child: Sparkle(seed: i + level * 31),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (luisaBuild && bannersClosed < 3)
              AlexBanner(
                key: ValueKey('banner$bannersClosed'),
                round: level + size + bannersClosed,
                onClose: () => setState(() => bannersClosed++),
              ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('Tippen = ✕ · Doppeltippen = Quokka setzen',
                  style: TextStyle(
                      color: Color(0xFFA1887F), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
