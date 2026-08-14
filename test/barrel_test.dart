import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// G8: a barrel can silently omit an export.
///
/// The web package shipped `ChartShell` documented in its manifest and missing
/// from `src/charts/index.ts` for months — documented, tested, and unreachable.
/// Nothing catches that except a check that the two agree.
///
/// This reads the manifest and the barrel as *text* rather than importing the
/// symbols, because a test that imports them is a test that stops compiling
/// when one goes missing, which is a worse failure message than a list of
/// names.
void main() {
  late Map<String, dynamic> manifest;
  late String barrelSource;
  late Set<String> exportedSymbols;

  setUpAll(() {
    manifest = jsonDecode(File('components.manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    barrelSource = File('lib/figuredout_ui.dart').readAsStringSync();
    exportedSymbols = _symbolsReachableThrough(barrelSource);
  });

  test('every manifest symbol is reachable through the barrel', () {
    final List<String> manifestSymbols = _manifestSymbols(manifest);
    expect(
      manifestSymbols.length,
      greaterThan(50),
      reason: 'the manifest parser found almost nothing — it has drifted',
    );

    final List<String> unreachable = manifestSymbols
        .where((String s) => !exportedSymbols.contains(s))
        .toList();

    expect(
      unreachable,
      isEmpty,
      reason: 'These are in components.manifest.json but not exported from '
          'lib/figuredout_ui.dart, so a consumer cannot use them however '
          'public they look: ${unreachable.join(', ')}',
    );
  });

  test('every exported symbol is in the manifest', () {
    final Set<String> manifestSymbols = _manifestSymbols(manifest).toSet();
    final List<String> undocumented = exportedSymbols
        .where((String s) => !manifestSymbols.contains(s))
        .toList();

    // The other direction matters too: a component nobody documented is a
    // component the next agent will build a second time.
    expect(
      undocumented,
      isEmpty,
      reason: 'These are exported but missing from components.manifest.json: '
          '${undocumented.join(', ')}',
    );
  });

  test('the barrel exports every file under lib/src', () {
    final List<String> sourceFiles = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path)
        .where((String p) => p.endsWith('.dart'))
        .map((String p) => p.replaceFirst('lib/', ''))
        .toList()
      ..sort();

    final List<String> missing = sourceFiles
        .where((String p) => !barrelSource.contains("export '$p';"))
        .toList();

    expect(
      missing,
      isEmpty,
      reason: 'These files exist under lib/src but nothing exports them: '
          '${missing.join(', ')}',
    );
  });
}

/// Every public symbol declared in a file the barrel exports.
Set<String> _symbolsReachableThrough(String barrelSource) {
  final Iterable<String> paths =
      RegExp(r"^export '(src/[^']+)';", multiLine: true)
          .allMatches(barrelSource)
          .map((RegExpMatch m) => m.group(1)!);

  final Set<String> symbols = <String>{};
  for (final String path in paths) {
    final String source = File('lib/$path').readAsStringSync();
    symbols.addAll(
      RegExp(
        r'^(?:abstract final class|final class|class|enum|extension|mixin)'
        r'\s+(Fo[A-Za-z0-9]*)',
        multiLine: true,
      ).allMatches(source).map((RegExpMatch m) => m.group(1)!),
    );
    // Top-level functions, e.g. foOverlaySurface.
    symbols.addAll(
      RegExp(
        r'^[A-Za-z<>?]+\s+(fo[A-Za-z0-9]*)\s*\(',
        multiLine: true,
      ).allMatches(source).map((RegExpMatch m) => m.group(1)!),
    );
  }
  return symbols;
}

List<String> _manifestSymbols(Map<String, dynamic> manifest) {
  final Map<String, dynamic> groups =
      manifest['groups'] as Map<String, dynamic>;
  return <String>[
    for (final dynamic group in groups.values)
      ...((group as Map<String, dynamic>)['symbols'] as List<dynamic>)
          .cast<String>(),
  ];
}
