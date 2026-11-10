/// Legacy deprecation logger for particles_network.
///
/// Formats and outputs bright yellow ANSI warning banners in debug mode
/// when deprecated APIs scheduled for removal in 2.0.0 are accessed.
library;

import 'package:flutter/foundation.dart';

/// Utility class for reporting deprecated API usages with bright yellow ANSI formatting.
class LegacyDeprecationLogger {
  static const String _yellow = '\x1B[33m';
  static const String _boldYellow = '\x1B[1;33m';
  static const String _reset = '\x1B[0m';

  static final Set<String> _warnedApis = <String>{};

  /// Resets the internal cache of warned APIs (useful for unit tests).
  @visibleForTesting
  static void resetWarned() {
    _warnedApis.clear();
  }

  /// Returns whether a given [deprecatedApi] has already logged a warning.
  @visibleForTesting
  static bool hasWarned(String deprecatedApi) =>
      _warnedApis.contains(deprecatedApi);

  /// Logs a formatted yellow warning in debug mode if the API hasn't been warned yet.
  static void warn({
    required String deprecatedApi,
    required String replacement,
  }) {
    if (!kDebugMode) return;
    if (_warnedApis.contains(deprecatedApi)) return;
    _warnedApis.add(deprecatedApi);

    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      '$_boldYellow════════════════════════════════════════════════════════════════════════════════$_reset',
    );
    buffer.writeln(
      '$_boldYellow[particles_network] ⚠️  DEPRECATION NOTICE (Scheduled for removal in v2.0.0)$_reset',
    );
    buffer.writeln('$_yellow• Deprecated API : $deprecatedApi$_reset');
    buffer.writeln('$_yellow• Recommended    : $replacement$_reset');
    buffer.writeln(
      '$_boldYellow════════════════════════════════════════════════════════════════════════════════$_reset',
    );

    debugPrint(buffer.toString());
  }
}

