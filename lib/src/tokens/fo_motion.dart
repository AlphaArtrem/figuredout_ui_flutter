import 'package:flutter/material.dart';

import 'fo_tokens.dart';

/// One duration pair and one curve — the whole motion vocabulary.
///
/// [normal] with [standard] for anything the eye follows; [fast] with
/// [standard] for anything under 200ms. `Curves.easeInOut`, `Curves.linear`
/// and any literal `Duration(...)` are banned outside this file, and
/// `test/tokens/no_literals_test.dart` enforces it: a system with four curves
/// has no curve at all.
abstract final class FoMotion {
  /// 150ms — a state change the user already knows about, because they caused
  /// it: a press, a hover, a focus ring arriving.
  static const Duration fast = FoTokens.durationFast;

  /// 250ms — a change the user has to notice: something entering, leaving,
  /// expanding or moving.
  static const Duration normal = FoTokens.durationNormal;

  /// `cubic-bezier(0.32, 0.72, 0, 1)` — decelerating hard into the end, so
  /// motion arrives rather than merely stopping.
  static const Cubic standard = FoTokens.easeStandard;

  /// One half-cycle of a skeleton's pulse, and the only thing allowed to use
  /// it. See [FoTokens.durationPulse] for why this is not a third duration.
  static const Duration pulse = FoTokens.durationPulse;
}
