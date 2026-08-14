import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The enforceable form of the web package's "a component must never hardcode
/// a colour, a shadow or a duration" — which over there is only a convention,
/// because no tool can check it.
///
/// Everything under `lib/src/` except `lib/src/tokens/` is scanned. Comments
/// are stripped first, so a doc comment may name a banned construct in order
/// to explain why it is banned.
void main() {
  final List<_Ban> bans = <_Ban>[
    _Ban(
      pattern: RegExp(r'Color\(0x'),
      message: 'a hex colour literal',
      fix: 'add it to FoTokens and reach it through context.foColors',
    ),
    _Ban(
      // Colors.transparent is the one allowed member: "no colour at all" is
      // not a design decision that could have been a token.
      pattern: RegExp(r'\bColors\.(?!transparent\b)\w+'),
      message: 'a Material palette colour',
      fix: 'use context.foColors — the Material palette is not this system',
    ),
    _Ban(
      pattern: RegExp(r'\bDuration\((?!\s*\))'),
      message: 'a duration literal',
      fix: 'use FoMotion.fast or FoMotion.normal',
    ),
    _Ban(
      pattern: RegExp(r'\bCurves\.(easeInOut|linear)\b'),
      message: 'an off-system curve',
      fix: 'use FoMotion.standard — one curve, or there is no curve',
    ),
    _Ban(
      // Zero is fine and in fact required: elevation in this system is painted
      // through BoxDecoration.boxShadow, never by Material.
      pattern: RegExp(r'\belevation:\s*(?!0\b)[0-9]'),
      message: 'a non-zero Material elevation',
      fix: 'use context.foShadows.raised / .hover / .overlay',
    ),
  ];

  test('lib/src outside tokens/ holds no design literals', () {
    final Directory src = Directory('lib/src');
    expect(
      src.existsSync(),
      isTrue,
      reason: 'run this from the package root',
    );

    final List<String> violations = <String>[];
    final List<File> scanned = <File>[];

    for (final FileSystemEntity entity in src.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('lib/src/tokens/')) continue;
      scanned.add(entity);

      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String line = _stripComment(lines[i]);
        for (final _Ban ban in bans) {
          final RegExpMatch? match = ban.pattern.firstMatch(line);
          if (match == null) continue;
          violations.add(
            '${entity.path}:${i + 1} — ${ban.message} (`${match.group(0)}`). '
            '${ban.fix}.',
          );
        }
      }
    }

    expect(
      scanned,
      isNotEmpty,
      reason: 'nothing was scanned — the path filter is wrong',
    );
    expect(violations, isEmpty, reason: '\n${violations.join('\n')}\n');
  });
}

class _Ban {
  _Ban({required this.pattern, required this.message, required this.fix});

  final RegExp pattern;
  final String message;
  final String fix;
}

/// Drops a trailing line comment. `//` inside a string would be dropped too,
/// which would only ever *hide* a violation in a string literal — not a shape
/// this package has, and the alternative is parsing Dart.
String _stripComment(String line) {
  final int index = line.indexOf('//');
  return index == -1 ? line : line.substring(0, index);
}
