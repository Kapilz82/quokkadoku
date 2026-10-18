// Nur im Luisa-Build aktiv: flutter build web --dart-define=LUISA=true
import 'dart:math';
import 'package:flutter/material.dart';

const luisaBuild = bool.fromEnvironment('LUISA');

// Texte hier anpassen; Alex, das ist deine Spielwiese.
const _niceWords = [
  'Ich finde deine Pflanzen toll.',
  'Ich finde dich toll.',
  'Ich kuschel gerne mit dir.',
  'Ich finde dich süß, wie du auf mir schläfst.',
  'Ich habe dich gerne an meiner Seite.',
  'Ich mag, wie du lachst.',
  'Mit dir ist sogar Nichtstun schön.',
  'Du bist mein Lieblingsmensch.',
  'Wenn du das liest: Ich denk grad an dich.',
  'Du bist klüger als jedes 10×10.',
  'Ich freu mich jedes Mal, wenn du nach Hause kommst.',
  'Mein Revier ist da, wo du bist.',
  'Du machst schlechte Tage gut.',
  'Ich mag es, wie du morgens noch ganz verschlafen bist.',
  'Ich mag deine Stimme, wenn du müde bist.',
  'Ich liebe es, mit dir einfach rumzuliegen.',
  'Ich mag, wie du dich über Kleinigkeiten freust.',
  'Du riechst nach Zuhause.',
  'Deine Umarmungen sind die besten.',
  'Ich mag es, wenn du mir von deinem Tag erzählst.',
  'Ich bin gern mit dir unterwegs. Egal wohin.',
  'Du bist wunderschön. Auch wenn du das gerade nicht glaubst.',
  'Du hast ein riesiges Herz.',
  'Ich bewundere, wie stark du bist.',
  'Du bist so lustig, ohne es zu merken.',
  'Deine Augen sind gefährlich schön.',
  'Du bist das Beste, was mir passiert ist.',
  'Du bist süßer als jedes Quokka.',
  'Wenn du ein Quokka wärst, wärst du das glücklichste.',
  'Achtung: Dieser Text enthält 100 % Liebe.',
  'Ein Kuss ist unterwegs. Lieferzeit: sobald du da bist.',
  'Kleine Erinnerung: Du schuldest mir noch eine Kuscheleinheit.',
  'Ich würde dir mein letztes Stück Sushi geben.',
  'Deine Pflanzen und ich sind uns einig: Du bist toll.',
  'Bei dir kann ich einfach ich sein.',
  'Ich bin dankbar für jeden Tag mit dir.',
  'Ich freu mich auf alles, was wir noch zusammen erleben.',
  'Danke, dass es dich gibt.',
  'Ich hab dich lieb. Mehr, als hier reinpasst.',
];

const _banners = [
  ('💌', 'Hier klicken für nette Dinge von Alex'),
  ('💋', 'Monatsabo Küsse: jetzt abschließen, 0 €'),
  ('🤗', 'Gratis-Umarmung. Nur heute. Und morgen.'),
];

/// Easter Eggs: Runde 10 bei diesen Größen schaltet eine Einladung frei.
const eggSizes = [7, 8, 10];

String eggTitle(int size) => switch (size) {
      7 => '🍣 Gutschein 1/3: Sushi-Date',
      8 => '🍣 Gutschein 2/3: Sushi-Date, zweite Runde',
      _ => '🍣 Gutschein 3/3: All-you-can-eat Sushi deluxe',
    };

String eggText(int size) => switch (size) {
      7 => 'Runde 10 bei 7×7 geschafft! Alex lädt dich zum '
          'All-you-can-eat Sushi ein. Tag und Uhrzeit bestimmst du.',
      8 => 'Runde 10 bei 8×8! Noch ein Sushi-Abend, diesmal mit Nachtisch. '
          'Alex zahlt, du bestellst.',
      _ => 'Runde 10 bei 10×10, das schaffen nur Profis. Großes Sushi-Date '
          'mit allem Drum und Dran. Du hast es dir verdient. ❤️',
    };

Future<void> showEgg(BuildContext context, int size) => Navigator.push(
    context, MaterialPageRoute(builder: (_) => AchievementPage(size: size)));

/// Gutschein als Achievement-Seite: zum Screenshotten gemacht.
class AchievementPage extends StatelessWidget {
  final int size;
  const AchievementPage({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6D4C41);
    final nr = eggSizes.indexOf(size) + 1;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆 ACHIEVEMENT 🏆',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Color(0xFFA1887F))),
                const SizedBox(height: 10),
                Text('Runde 10 bei $size×$size',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: brown)),
                const SizedBox(height: 20),
                // Gutschein-Karte
                Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFE0A3), Color(0xFFFFC9C9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: brown, width: 3),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.elasticOut,
                        builder: (_, t, child) =>
                            Transform.scale(scale: t, child: child),
                        child: const Text('🍣',
                            style: TextStyle(fontSize: 90)),
                      ),
                      const SizedBox(height: 8),
                      Text(eggTitle(size).replaceFirst('🍣 ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: brown)),
                      const SizedBox(height: 12),
                      Text(eggText(size),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: brown)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                            'Gutschein-Nr. QK-$size$size-00$nr · Gültig: immer',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: brown)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEBDCC8))),
                  child: const Text(
                    '📸 Einlösen: Screenshot von diesem Gutschein machen '
                    'und an Alex schicken.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: brown),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Weiterspielen'),
                ),
                const SizedBox(height: 8),
                const Text('Im Menü unter „Meine Gutscheine" jederzeit wieder zu finden.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFFA1887F))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liste der verdienten Gutscheine (Menüpunkt).
Future<void> showVouchers(BuildContext context, Set<int> earned) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFF6E9),
        title: const Text('🍣 Meine Gutscheine',
            style: TextStyle(
                color: Color(0xFF6D4C41), fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in eggSizes)
              ListTile(
                enabled: earned.contains(s),
                leading: Text(earned.contains(s) ? '🍣' : '🔒',
                    style: const TextStyle(fontSize: 24)),
                title: Text(earned.contains(s)
                    ? eggTitle(s).replaceFirst('🍣 ', '')
                    : 'Gutschein ${eggSizes.indexOf(s) + 1}/3'),
                subtitle: Text(earned.contains(s)
                    ? 'Antippen zum Ansehen'
                    : 'Erreiche Runde 10 bei $s×$s'),
                onTap: earned.contains(s)
                    ? () {
                        Navigator.pop(context);
                        showEgg(context, s);
                      }
                    : null,
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'))
        ],
      ),
    );

/// Werbebanner-Parodie unter dem Brett.
class AlexBanner extends StatelessWidget {
  final int round; // wechselt den Banner der Reihe nach
  final VoidCallback onClose;
  const AlexBanner({super.key, required this.round, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final (icon, text) = _banners[round % _banners.length];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: const Color(0xFFFFE0A3),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFFFFF6E9),
              title: Text(icon, style: const TextStyle(fontSize: 40)),
              content: Text(
                icon == '💌'
                    ? _niceWords[Random().nextInt(_niceWords.length)]
                    : icon == '💋'
                        ? 'Abo abgeschlossen! Einlösbar bei Alex, '
                            'jederzeit, unbegrenzt. Kündigung ausgeschlossen.'
                        : 'Umarmung reserviert. Abholung bei Alex.',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('❤️'))
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6D4C41))),
                ),
                const Text('Anzeige',
                    style: TextStyle(fontSize: 10, color: Color(0xFFA1887F))),
                IconButton(
                  tooltip: 'Wegdrücken',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close,
                      size: 18, color: Color(0xFFA1887F)),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
