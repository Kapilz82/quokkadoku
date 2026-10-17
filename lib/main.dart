import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle.dart';
import 'quokka.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Quokkadoku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFB07A3C),
          scaffoldBackgroundColor: const Color(0xFFFFF7EC),
          useMaterial3: true,
        ),
        home: const GamePage(),
      );
}

const _regionColors = [
  Color(0xFFFFC9C9),
  Color(0xFFFFE0A3),
  Color(0xFFFFF59D),
  Color(0xFFC8E6C9),
  Color(0xFFB2EBF2),
  Color(0xFFBBDEFB),
  Color(0xFFD1C4E9),
  Color(0xFFF8BBD0),
  Color(0xFFD7CCC8),
  Color(0xFFCFD8DC),
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
  bool autoCross = false; // Luisa setzt ihre ✕ lieber selbst
  late Puzzle puzzle;
  late List<List<Mark>> marks;
  int hearts = 3;
  bool loaded = false;
  (int, int)? wrong; // Feld, das gerade rot aufblitzt
  final floats = <_Float>[];
  int floatId = 0;
  int sparkles = 0; // > 0 während der Gewinn-Konfetti

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      size = p.getInt('size') ?? 7;
      level = p.getInt('level_$size') ?? 1;
      score = p.getInt('score') ?? 0;
      autoCross = p.getBool('autoCross') ?? false;
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
    puzzle = Puzzle.forLevel(level, size);
    marks = List.generate(puzzle.n, (_) => List.filled(puzzle.n, Mark.none));
    hearts = 3;
    wrong = null;
    if (mounted) setState(() => loaded = true);
  }

  int get placed =>
      marks.expand((r) => r).where((m) => m == Mark.quokka).length;

  void _tap(int r, int c) {
    if (marks[r][c] == Mark.quokka) return;
    setState(() =>
        marks[r][c] = marks[r][c] == Mark.cross ? Mark.none : Mark.cross);
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
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text(button))
          ],
        ),
      );

  void _rules() => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('So geht Quokkadoku'),
          content: const Text(
            '🏡 In jedem farbigen Gebiet wohnt genau ein Quokka.\n\n'
            '↔️ In jeder Zeile und jeder Spalte sitzt genau eines.\n\n'
            '🚫 Quokkas berühren sich nie, auch nicht diagonal.\n\n'
            '👆 Tippen setzt ein ✕ auf Felder, wo keins sitzen kann.\n'
            '👆👆 Doppeltippen setzt ein Quokka. Falsch = ein Herz weg, '
            'drei Fehler = Runde von vorn.\n\n'
            '💡 Die Glühbirne deckt ein Quokka auf (ohne Punkte).\n'
            '⚙️ Im Menü: Feldgröße und ob ✕ automatisch gesetzt werden.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Alles klar'))
          ],
        ),
      );

  Future<void> _won() async {
    final bonus = hearts * 20 * puzzle.n;
    setState(() {
      sparkles = 12;
      _addPoints(puzzle.n ~/ 2, puzzle.n ~/ 2, bonus);
    });
    level++;
    (await SharedPreferences.getInstance()).setInt('level_$size', level);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _dialog('Alle Quokkas zuhause! 🎉',
        'Herz-Bonus +$bonus\nWeiter zu Runde $level', 'Los');
    setState(() {
      sparkles = 0;
      _start();
    });
  }

  Future<void> _lost() async {
    await _dialog('Keine Herzen mehr 💔', 'Nochmal versuchen?', 'Nochmal');
    _start();
  }

  Widget _cell(int r, int c, int n) {
    final id = puzzle.region[r][c];
    BorderSide side(int rr, int cc) =>
        (rr < 0 || rr >= n || cc < 0 || cc >= n || puzzle.region[rr][cc] != id)
            ? const BorderSide(color: Color(0xFF5D4037), width: 2.5)
            : const BorderSide(color: Colors.black12, width: 0.5);
    final mark = marks[r][c];
    return GestureDetector(
      onTap: () => _tap(r, c),
      onDoubleTap: () => _doubleTap(r, c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: wrong == (r, c)
              ? Colors.red.shade300
              : _regionColors[id % _regionColors.length],
          border: Border(
            top: side(r - 1, c),
            bottom: side(r + 1, c),
            left: side(r, c - 1),
            right: side(r, c + 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: switch (mark) {
              Mark.none => const SizedBox.expand(key: ValueKey(0)),
              Mark.cross => Center(
                  key: const ValueKey(1),
                  child: Text('✕',
                      style: TextStyle(
                          fontSize: 160 / n,
                          color: Colors.black38,
                          fontWeight: FontWeight.bold)),
                ),
              Mark.quokka => const Quokka(key: ValueKey(2)),
            },
          ),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE7C7),
        title: Text('Runde $level · ${Puzzle.difficulty(n)} · $n×$n'),
        actions: [
          IconButton(
            tooltip: 'Spielanleitung',
            icon: const Icon(Icons.info_outline),
            onPressed: _rules,
          ),
          PopupMenuButton<int>(
            tooltip: 'Einstellungen',
            icon: const Icon(Icons.tune),
            initialValue: size,
            onSelected: _menu,
            itemBuilder: (_) => [
              for (final n in Puzzle.sizes)
                PopupMenuItem(
                    value: n, child: Text('$n×$n · ${Puzzle.difficulty(n)}')),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                  value: -1,
                  checked: autoCross,
                  child: const Text('✕ automatisch setzen')),
            ],
          ),
          IconButton(
            tooltip: 'Tipp: einen Quokka aufdecken',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _hint,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '❤️' * hearts + '🤍' * (3 - hearts),
                  key: ValueKey(hearts),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ein Kästchen pro Gebiet: gefüllt, sobald sein Quokka sitzt.
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < n; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _regionColors[i % _regionColors.length],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF5D4037),
                          width: marks[i][puzzle.solution[i]] == Mark.quokka
                              ? 2.5
                              : 1),
                    ),
                    child: marks[i][puzzle.solution[i]] == Mark.quokka
                        ? const Padding(
                            padding: EdgeInsets.all(2), child: Quokka())
                        : null,
                  ),
                const SizedBox(width: 10),
                Text('$placed / $n',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0A3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: score),
                duration: const Duration(milliseconds: 600),
                builder: (_, v, child) => Text('⭐ $v Punkte',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (_, box) {
                      final cell = box.maxWidth / n;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF5D4037), width: 3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: n),
                                itemCount: n * n,
                                itemBuilder: (_, i) =>
                                    _cell(i ~/ n, i % n, n),
                              ),
                            ),
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
                                  onDone: () => setState(() => floats.remove(f)),
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
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Tippen = ✕ · Doppeltippen = Quokka setzen',
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
