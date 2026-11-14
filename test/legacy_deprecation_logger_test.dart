import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particles_network/src/legacy/legacy_deprecation_logger.dart';

void main() {
  setUp(() {
    LegacyDeprecationLogger.resetWarned();
  });

  tearDown(() {
    LegacyDeprecationLogger.resetWarned();
  });

  group('LegacyDeprecationLogger', () {
    test('logs deprecation warning in debug mode for new API', () {
      final List<String> printedMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) printedMessages.add(message);
      };

      try {
        const api = 'ParticleNetwork(legacyParam)';
        const replacement = 'ParticleNetwork(modernParam: ...)';

        expect(LegacyDeprecationLogger.hasWarned(api), isFalse);

        LegacyDeprecationLogger.warn(
          deprecatedApi: api,
          replacement: replacement,
        );

        expect(LegacyDeprecationLogger.hasWarned(api), isTrue);
        expect(printedMessages, hasLength(1));
        expect(printedMessages.first, contains('DEPRECATION NOTICE'));
        expect(printedMessages.first, contains(api));
        expect(printedMessages.first, contains(replacement));
      } finally {
        debugPrint = originalDebugPrint;
      }
    });

    test('returns immediately and does not log when not in debug mode (L33)',
        () {
      final List<String> printedMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) printedMessages.add(message);
      };

      try {
        LegacyDeprecationLogger.isDebugMode = false;
        const api = 'ParticleNetwork(nonDebugParam)';
        const replacement = 'ParticleNetwork(replacement: ...)';

        LegacyDeprecationLogger.warn(
          deprecatedApi: api,
          replacement: replacement,
        );

        expect(LegacyDeprecationLogger.hasWarned(api), isFalse);
        expect(printedMessages, isEmpty);
      } finally {
        debugPrint = originalDebugPrint;
      }
    });

    test('returns immediately and ignores duplicate warnings (L34)', () {
      final List<String> printedMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) printedMessages.add(message);
      };

      try {
        const api = 'ParticleNetwork(duplicateParam)';
        const replacement = 'ParticleNetwork(modernParam: ...)';

        // First call: logs warning
        LegacyDeprecationLogger.warn(
          deprecatedApi: api,
          replacement: replacement,
        );
        expect(printedMessages, hasLength(1));
        expect(LegacyDeprecationLogger.hasWarned(api), isTrue);

        // Second call: duplicate warning, early return on L34
        LegacyDeprecationLogger.warn(
          deprecatedApi: api,
          replacement: replacement,
        );
        expect(printedMessages, hasLength(1));
      } finally {
        debugPrint = originalDebugPrint;
      }
    });

    test('resetWarned clears cache and resets isDebugMode', () {
      LegacyDeprecationLogger.isDebugMode = false;
      const api = 'ParticleNetwork(resetTest)';
      LegacyDeprecationLogger.warn(
        deprecatedApi: api,
        replacement: 'Replacement',
      );
      expect(LegacyDeprecationLogger.hasWarned(api), isFalse);

      LegacyDeprecationLogger.resetWarned();
      expect(LegacyDeprecationLogger.isDebugMode, equals(kDebugMode));
      expect(LegacyDeprecationLogger.hasWarned(api), isFalse);
    });
  });
}
