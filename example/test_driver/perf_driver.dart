// Host-side driver for integration_test/perf_benchmark_test.dart.
//
// Writes the collected frame statistics to build/perf/<label>.json, where
// <label> comes from the PERF_LABEL environment variable (default: a
// timestamp). Compare two runs with `dart run tool/compare_perf.dart`.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (data == null) return;
      final String label = Platform.environment['PERF_LABEL'] ??
          DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('build/perf/$label.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
      stdout.writeln('Perf results written to ${file.path}');
    },
  );
}
