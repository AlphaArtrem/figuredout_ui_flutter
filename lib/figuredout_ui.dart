/// `figuredout_ui` — the Flutter design system for FiguredOut apps, and the
/// sibling of the React package `@figuredout/ui-web`.
///
/// This is the single public barrel. A symbol not exported here does not
/// exist as far as a consumer is concerned, however public it looks in
/// `lib/src/` — see AGENTS.md, "a barrel can silently omit an export".
///
/// Read `docs/components.md` before changing anything: it carries the surface
/// ladder, the five rules, and the gotchas that have already cost someone an
/// afternoon.
library;

// ─── Theme ──────────────────────────────────────────────────────────────────
export 'src/theme/fo_context.dart';
export 'src/theme/fo_theme.dart';
export 'src/theme/fo_theme_ext.dart';
export 'src/theme/fo_window_class.dart';

// ─── Tokens ─────────────────────────────────────────────────────────────────
export 'src/tokens/fo_chart_colors.dart';
export 'src/tokens/fo_colors.dart';
export 'src/tokens/fo_layout.dart';
export 'src/tokens/fo_motion.dart';
export 'src/tokens/fo_shadows.dart';
export 'src/tokens/fo_tokens.dart';
export 'src/tokens/fo_typography.dart';
