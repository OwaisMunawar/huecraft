import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huecraft/features/studio/data/proposal_engines.dart';
import 'package:huecraft/features/studio/domain/color_value.dart';
import 'package:huecraft/features/studio/domain/palette.dart';
import 'package:huecraft/features/studio/domain/solver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('huecraft-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final options = proposalOptions(initialPalette, sampleCatalog, {});
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test('rules are deterministic and explicitly labelled', () async {
    final rules = RulesProposalEngine();
    expect(await rules.available(), isTrue);
    expect(rules.label, contains('no model'));
    expect(await rules.choose('calm studio', options), 0);
    expect(await rules.choose('bold studio', options), 1 % options.length);
    expect(await rules.choose('warm studio', options), 2 % options.length);
    await expectLater(
      rules.choose('x', options),
      throwsA(isA<StudioFailure>()),
    );
    await expectLater(
      rules.choose('a' * 401, options),
      throwsA(isA<StudioFailure>()),
    );
    await expectLater(
      rules.choose('calm studio', []),
      throwsA(isA<StudioFailure>()),
    );
    final disabled = DisabledProposalEngine();
    expect(await disabled.available(), isFalse);
    expect(disabled.label, 'No model');
    await expectLater(
      disabled.choose('calm studio', options),
      throwsA(isA<StudioFailure>()),
    );
  });
  test(
    'native channel passes bounded candidates and validates indexes',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'available') return true;
        final args = call.arguments as Map<Object?, Object?>;
        expect(args['brief'], 'Calm studio');
        expect((args['options']! as List<Object?>).length, options.length);
        return 0;
      });
      final engine = NativeProposalEngine(channel: channel);
      expect(await engine.available(), isTrue);
      expect(engine.label, 'On-device AI');
      expect(await engine.choose(' Calm studio ', options), 0);
      for (final value in [null, true, '0', -1, 3]) {
        messenger.setMockMethodCallHandler(channel, (_) async => value);
        await expectLater(
          engine.choose('Calm studio', options),
          throwsA(isA<StudioFailure>()),
        );
      }
      await expectLater(
        engine.choose('Calm studio', []),
        throwsA(isA<StudioFailure>()),
      );
      await expectLater(
        engine.choose('Calm studio', [...options, ...options, ...options]),
        throwsA(isA<StudioFailure>()),
      );
    },
  );
  test(
    'missing bridge, native failure and timeout never pretend to succeed',
    () async {
      final engine = NativeProposalEngine(
        channel: channel,
        timeout: const Duration(milliseconds: 5),
      );
      expect(await engine.available(), isFalse);
      await expectLater(
        engine.choose('Calm studio', options),
        throwsA(isA<StudioFailure>()),
      );
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      expect(await engine.available(), isFalse);
      await expectLater(
        engine.choose('Calm studio', options),
        throwsA(isA<StudioFailure>()),
      );
      messenger.setMockMethodCallHandler(channel, (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 0;
      });
      await expectLater(
        engine.choose('Calm studio', options),
        throwsA(
          isA<StudioFailure>().having(
            (e) => e.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 55));
    },
  );
}
