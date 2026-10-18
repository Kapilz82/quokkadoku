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

Future<void> showEgg(BuildContext context, int size) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFF6E9),
        title: Text(eggTitle(size),
            style: const TextStyle(
                color: Color(0xFF6D4C41), fontWeight: FontWeight.w900)),
        content: Text(eggText(size), style: const TextStyle(fontSize: 16)),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Einlösen bei Alex'))
        ],
      ),
    );

/// Werbebanner-Parodie unter dem Brett. Wechselt bei jedem Aufbau.
class AlexBanner extends StatelessWidget {
  const AlexBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, text) = _banners[Random().nextInt(_banners.length)];
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
