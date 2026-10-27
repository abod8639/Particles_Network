// Compares two perf result files produced by test_driver/perf_driver.dart.
//
//   dart run tool/compare_perf.dart build/perf/before.json build/perf/after.json
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const List<String> _metrics = [
  'fps',
  'jank_ratio',
  'build_p90_ms',
  'raster_p50_ms',
  'raster_p90_ms',
];

Map<String, dynamic> _load(String path) {
  final data = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return data['scenarios'] as Map<String, dynamic>;
}

String _cell(Object? v) => (v?.toString() ?? '-').padLeft(8);

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: compare_perf.dart <before.json> <after.json>');
    exit(64);
  }
  final before = _load(args[0]);
  final after = _load(args[1]);
  final names = {...before.keys, ...after.keys};

  for (final metric in _metrics) {
    print('\n$metric');
    print('${'scenario'.padRight(26)}${'before'.padLeft(8)}'
        '${'after'.padLeft(8)}${'delta'.padLeft(9)}');
    for (final name in names) {
      final num? b = (before[name] as Map?)?[metric] as num?;
      final num? a = (after[name] as Map?)?[metric] as num?;
      String delta = '-';
      if (a != null && b != null && b != 0) {
        final double pct = (a - b) / b * 100;
        delta = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%';
      }
      print('${name.padRight(26)}${_cell(b)}${_cell(a)}${delta.padLeft(9)}');
    }
  }
}
