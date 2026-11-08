import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/color_value.dart';
import '../domain/palette.dart';
import '../domain/ports.dart';

final class RulesProposalEngine implements ProposalEngine {
  @override
  String get label => 'Rules · no model';
  @override
  Future<bool> available() async => true;
  @override
  Future<int> choose(String brief, List<PaletteOption> options) async {
    validateBrief(brief);
    if (options.isEmpty) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'No valid directions are available.',
      );
    }
    final normalized = brief.toLowerCase();
    return (normalized.contains('bold')
            ? 1
            : normalized.contains('warm')
            ? 2
            : 0) %
        options.length;
  }
}

void validateBrief(String brief) {
  if (brief.trim().length < 3 || brief.length > 400) {
    throw const StudioFailure(
      FailureCode.invalidInput,
      'Describe a direction in 3–400 characters.',
    );
  }
}

final class NativeProposalEngine implements ProposalEngine {
  NativeProposalEngine({
    MethodChannel? channel,
    this.timeout = const Duration(seconds: 45),
  }) : channel =
           channel ??
           const MethodChannel('com.owaismunawar.huecraft/intelligence');
  final MethodChannel channel;
  final Duration timeout;
  @override
  String get label => 'On-device AI';
  @override
  Future<bool> available() async {
    try {
      return await channel
              .invokeMethod<bool>('available')
              .timeout(const Duration(seconds: 3)) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  @override
  Future<int> choose(String brief, List<PaletteOption> options) async {
    validateBrief(brief);
    if (options.isEmpty || options.length > 3) {
      throw const StudioFailure(
        FailureCode.invalidInput,
        'Offer one to three validated directions.',
      );
    }
    try {
      final result = await channel
          .invokeMethod<Object?>('choose', {
            'brief': brief.trim(),
            'options': [
              for (final option in options)
                {'title': option.title, 'colors': option.palette.toJson()},
            ],
          })
          .timeout(timeout);
      if (result is! int || result < 0 || result >= options.length) {
        throw const StudioFailure(
          FailureCode.model,
          'The model returned an invalid direction. Nothing was applied.',
        );
      }
      return result;
    } on PlatformException {
      throw const StudioFailure(
        FailureCode.unavailable,
        'The on-device model could not complete this request. Try again or select Rules.',
      );
    } on MissingPluginException {
      throw const StudioFailure(
        FailureCode.unavailable,
        'This build has no native model. Select Rules.',
      );
    } on TimeoutException {
      throw const StudioFailure(
        FailureCode.model,
        'The proposal timed out. Nothing was applied.',
      );
    }
  }
}
