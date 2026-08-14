import 'package:flutter/material.dart';

/// Raw design tokens — the single source of truth for every literal value in
/// the system, and the **only** file allowed to hold one.
///
/// Colours are ported verbatim from `@figuredout/ui-web`'s
/// `styles/tokens.css`. If a value here looks wrong, fix it in the web package
/// first so the two stay in step. `rgba(r, g, b, a)` becomes
/// `Color(0xAARRGGBB)` with `AA = round(a * 255)`.
///
/// Metrics are *not* ported from the web: they are kept from Luxe, because the
/// consuming apps run on shop-floor tablets where a 48dp touch target and a
/// 56dp field are load-bearing.
///
/// Widgets must never read this class directly — go through `context.foColors`
/// / `.foText` / `.foSpacing` (see `FoThemeExt`). `test/tokens/
/// no_literals_test.dart` enforces that.
abstract final class FoTokens {
  /// The font family package. Every [TextStyle] carrying `fontFamily` must
  /// also carry `package: FoTokens.fontPackage`, or the family resolves
  /// against the *consuming app's* manifest and silently falls back to Roboto.
  static const String fontPackage = 'figuredout_ui';

  /// Geist — the sans family, for everything that is prose or a control.
  static const String fontSans = 'Geist';

  /// Geist Mono — for captions that name a value and figures that are one.
  static const String fontMono = 'GeistMono';

  // ─── Light surfaces — a four-step ladder, and the order is meaning ────────
  // sunken (a hole) < bg (the page) < surface (rests) < raised (lifted).
  // White is the TOP of the ladder, not the resting surface.

  /// Light: the page itself.
  static const Color bg = Color(0xFFF1F4F0);

  /// Light: cards, tables, panels — anything resting on the page.
  static const Color surface = Color(0xFFF9FBF8);

  /// Light: anything lifted — dialog, menu, toast, hovered row, open tile.
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Light: holes — text fields, segmented-control tracks, wells.
  static const Color surfaceSunken = Color(0xFFE7EBE5);

  // ─── Light ink ────────────────────────────────────────────────────────────

  /// Light: primary ink.
  static const Color fg = Color(0xFF0F1310);

  /// Light: secondary ink — supporting prose, captions.
  static const Color fgMuted = Color(0xFF333C35);

  /// Light: tertiary ink — the quietest readable step.
  static const Color fgSubtle = Color(0xFF4E574F);

  /// Light: hairlines.
  static const Color edge = Color(0xFFDBE1D9);

  /// Light: a hairline that has to be found rather than merely obeyed.
  static const Color edgeStrong = Color(0xFFA7B0A5);

  // ─── Light semantic ───────────────────────────────────────────────────────

  /// Light: the brand hue.
  static const Color primary = Color(0xFF15803D);

  /// Light: primary under a pointer.
  static const Color primaryHover = Color(0xFF166534);

  /// Light: ink on [primary].
  static const Color primaryFg = Color(0xFFF0FDF4);

  /// Light: `rgba(21, 128, 61, 0.12)`.
  static const Color primarySoft = Color(0x1F15803D);

  /// Light: `rgba(21, 128, 61, 0.34)` — the one focus treatment.
  static const Color focusRing = Color(0x5715803D);

  /// Light: success. Darkened from `#16a34a` on the web side, which reached
  /// only 3.17:1 on `surface` and 2.77:1 on its own soft wash.
  static const Color success = Color(0xFF0F7434);

  /// Light: `rgba(22, 163, 74, 0.12)`.
  static const Color successSoft = Color(0x1F16A34A);

  /// Light: warning.
  static const Color warning = Color(0xFF713F12);

  /// Light: `rgba(250, 204, 21, 0.16)`.
  static const Color warningSoft = Color(0x29FACC15);

  /// Light: danger.
  static const Color danger = Color(0xFF7F1D1D);

  /// Light: ink on [danger]. Danger carries its own ink — [primaryFg] is the
  /// ink for PRIMARY, and in dark mode it is a near-black green, which on a
  /// light red is unreadable.
  static const Color dangerFg = Color(0xFFFFF1F2);

  /// Light: `rgba(248, 113, 113, 0.14)`.
  static const Color dangerSoft = Color(0x24F87171);

  /// Light: information.
  static const Color info = Color(0xFF1E3A8A);

  /// Light: `rgba(96, 165, 250, 0.14)`.
  static const Color infoSoft = Color(0x2460A5FA);

  /// Light: accent.
  static const Color accent = Color(0xFF7C2D12);

  /// Light: ink on [accent].
  static const Color accentFg = Color(0xFFFFF7ED);

  // ─── Dark surfaces ────────────────────────────────────────────────────────

  /// Dark: the page itself.
  static const Color bgDark = Color(0xFF111113);

  /// Dark: cards, tables, panels.
  static const Color surfaceDark = Color(0xFF18191B);

  /// Dark: anything lifted.
  static const Color surfaceRaisedDark = Color(0xFF212225);

  /// Dark: holes.
  static const Color surfaceSunkenDark = Color(0xFF151619);

  // ─── Dark ink ─────────────────────────────────────────────────────────────

  /// Dark: primary ink.
  static const Color fgDark = Color(0xFFFAFAFA);

  /// Dark: secondary ink.
  static const Color fgMutedDark = Color(0xFFA1A1AA);

  /// Dark: tertiary ink.
  static const Color fgSubtleDark = Color(0xFF8A8A8F);

  /// Dark: hairlines.
  static const Color edgeDark = Color(0xFF272A2D);

  /// Dark: a findable hairline.
  static const Color edgeStrongDark = Color(0xFF43484E);

  // ─── Dark semantic ────────────────────────────────────────────────────────

  /// Dark: the brand hue.
  static const Color primaryDark = Color(0xFF86EFAC);

  /// Dark: primary under a pointer.
  static const Color primaryHoverDark = Color(0xFFBBF7D0);

  /// Dark: ink on [primaryDark].
  static const Color primaryFgDark = Color(0xFF052E16);

  /// Dark: `rgba(34, 197, 94, 0.16)`.
  static const Color primarySoftDark = Color(0x2922C55E);

  /// Dark: `rgba(134, 239, 172, 0.36)`.
  static const Color focusRingDark = Color(0x5C86EFAC);

  /// Dark: success.
  static const Color successDark = Color(0xFF5DDF6C);

  /// Dark: `rgba(93, 223, 108, 0.16)`.
  static const Color successSoftDark = Color(0x295DDF6C);

  /// Dark: warning.
  static const Color warningDark = Color(0xFFEAB308);

  /// Dark: `rgba(66, 32, 6, 0.78)`.
  static const Color warningSoftDark = Color(0xC7422006);

  /// Dark: danger.
  static const Color dangerDark = Color(0xFFF87171);

  /// Dark: ink on [dangerDark].
  static const Color dangerFgDark = Color(0xFF450A0A);

  /// Dark: `rgba(69, 10, 10, 0.78)`.
  static const Color dangerSoftDark = Color(0xC7450A0A);

  /// Dark: information.
  static const Color infoDark = Color(0xFF60A5FA);

  /// Dark: `rgba(30, 58, 138, 0.36)`.
  static const Color infoSoftDark = Color(0x5C1E3A8A);

  /// Dark: accent.
  static const Color accentDark = Color(0xFFFB923C);

  /// Dark: ink on [accentDark].
  static const Color accentFgDark = Color(0xFF431407);

  // ─── Charts ───────────────────────────────────────────────────────────────
  // Series hues never carry status meaning; status uses the semantic palette.

  /// Light: categorical series 1–6.
  static const List<Color> chartCategorical = <Color>[
    Color(0xFF15803D),
    Color(0xFF1E3A8A),
    Color(0xFF7C2D12),
    Color(0xFF7F1D1D),
    Color(0xFF713F12),
    Color(0xFF4B4C52),
  ];

  /// Dark: categorical series 1–6.
  static const List<Color> chartCategoricalDark = <Color>[
    Color(0xFF86EFAC),
    Color(0xFF60A5FA),
    Color(0xFFFB923C),
    Color(0xFFF87171),
    Color(0xFFEAB308),
    Color(0xFFA1A1AA),
  ];

  /// Light: the single hue a sequential scale ramps through.
  static const Color chartSequential = Color(0xFF15803D);

  /// Dark: the single hue a sequential scale ramps through.
  static const Color chartSequentialDark = Color(0xFF86EFAC);

  /// Light: `rgba(15, 19, 16, 0.10)`.
  static const Color chartGrid = Color(0x1A0F1310);

  /// Dark: `rgba(250, 250, 250, 0.12)`.
  static const Color chartGridDark = Color(0x1FFAFAFA);

  /// Light: axis tick labels.
  static const Color chartAxisLabel = Color(0xFF4E574F);

  /// Dark: axis tick labels.
  static const Color chartAxisLabelDark = Color(0xFFA1A1AA);

  /// Light: a target/threshold rule on a chart. Flutter-only — the web
  /// package has no equivalent; it tracks [fgSubtle].
  static const Color chartTargetLine = Color(0xFF4E574F);

  /// Dark: a target/threshold rule on a chart. Tracks [edgeStrongDark].
  static const Color chartTargetLineDark = Color(0xFF43484E);

  // ─── Elevation ────────────────────────────────────────────────────────────
  // Tinted with the ground's own hue rather than black: a black shadow on a
  // tinted surface greys out the colour beneath it and reads as dirt. Being
  // hue-matched also lets them run at a lower opacity.

  /// Light: `rgba(16, 32, 22, 0.05)`.
  static const Color shadowRaisedNear = Color(0x0D102016);

  /// Light: `rgba(16, 32, 22, 0.07)`.
  static const Color shadowRaisedFar = Color(0x12102016);

  /// Light: `rgba(16, 32, 22, 0.07)`.
  static const Color shadowHoverNear = Color(0x12102016);

  /// Light: `rgba(16, 32, 22, 0.11)`.
  static const Color shadowHoverFar = Color(0x1C102016);

  /// Light: `rgba(16, 32, 22, 0.08)`.
  static const Color shadowOverlayNear = Color(0x14102016);

  /// Light: `rgba(16, 32, 22, 0.16)`.
  static const Color shadowOverlayFar = Color(0x29102016);

  /// Dark: `rgba(0, 0, 0, 0.24)`.
  static const Color shadowRaisedNearDark = Color(0x3D000000);

  /// Dark: `rgba(0, 0, 0, 0.30)`.
  static const Color shadowRaisedFarDark = Color(0x4D000000);

  /// Dark: `rgba(0, 0, 0, 0.28)`.
  static const Color shadowHoverNearDark = Color(0x47000000);

  /// Dark: `rgba(0, 0, 0, 0.38)`.
  static const Color shadowHoverFarDark = Color(0x61000000);

  /// Dark: `rgba(0, 0, 0, 0.28)`.
  static const Color shadowOverlayNearDark = Color(0x47000000);

  /// Dark: `rgba(0, 0, 0, 0.38)`.
  static const Color shadowOverlayFarDark = Color(0x61000000);

  // ─── Motion ───────────────────────────────────────────────────────────────

  /// `--motion-fast`.
  static const Duration durationFast = Duration(milliseconds: 150);

  /// `--motion-normal`.
  static const Duration durationNormal = Duration(milliseconds: 250);

  /// `--ease-standard`, `cubic-bezier(0.32, 0.72, 0, 1)`.
  static const Cubic easeStandard = Cubic(0.32, 0.72, 0.0, 1.0);

  /// One half-cycle of a skeleton's pulse.
  ///
  /// Deliberately not a third UI duration: [durationFast] and [durationNormal]
  /// time a *transition* — something moving from one state to another — while
  /// this is the period of a loop that has no destination. Nothing but a
  /// skeleton may use it.
  static const Duration durationPulse = Duration(milliseconds: 900);

  /// How long a toast confirming something stays.
  static const Duration durationToastShort = Duration(seconds: 4);

  /// How long a toast the user actually has to read stays. A failure is news;
  /// a success confirms something they already know they did.
  static const Duration durationToastLong = Duration(seconds: 6);

  /// How long a search box waits before asking the server. Long enough that
  /// typing a word is one request rather than five, short enough not to feel
  /// stuck.
  static const Duration durationSearchDebounce = Duration(milliseconds: 300);

  // ─── Opacity ──────────────────────────────────────────────────────────────

  /// The alpha a semantic ink is washed at to become its own soft ground.
  /// Matches the `-soft` tokens, so a chip tinted from an arbitrary colour
  /// lands at the same weight as one tinted from `primarySoft`.
  static const double softWashAlpha = 0.12;

  /// Disabled ink: present enough to read, plainly not actionable.
  static const double disabledInkOpacity = 0.5;

  /// Disabled fill. Slightly further down than the ink, so a disabled filled
  /// button does not read as a lighter *enabled* one.
  static const double disabledFillOpacity = 0.45;

  /// A pointer resting on something interactive.
  static const double hoverOverlayOpacity = 0.08;

  /// A press. One step past [hoverOverlayOpacity], not a different idea.
  static const double pressedOverlayOpacity = 0.12;

  /// How strongly a soft-washed surface draws its own edge.
  static const double bannerEdgeOpacity = 0.32;

  // ─── Icon sizes ───────────────────────────────────────────────────────────

  /// An icon beside body text, in a table cell, or inside a control.
  static const double iconSmall = 18.0;

  /// An icon that is the control.
  static const double iconMedium = 24.0;

  /// The spinner inside a button, matched to the cap height beside it.
  static const double spinnerSmall = 18.0;

  /// A spinner standing in for a region rather than a control.
  static const double spinnerMedium = 32.0;

  /// A spinner's stroke. Thin enough to read as motion, not as a ring.
  static const double spinnerStroke = 2.0;

  // ─── Skeletons ────────────────────────────────────────────────────────────

  /// The floor of a skeleton's pulse.
  static const double skeletonPulseMin = 0.4;

  /// The ceiling of a skeleton's pulse.
  static const double skeletonPulseMax = 0.8;

  /// The value a skeleton freezes at when the platform asks for reduced
  /// motion — the midpoint, so it reads as deliberate rather than stalled.
  static const double skeletonPulseStill = 0.6;

  // ─── Spacing scale (Luxe's, not the web's) ────────────────────────────────

  /// 4dp.
  static const double space4 = 4.0;

  /// 8dp.
  static const double space8 = 8.0;

  /// 12dp.
  static const double space12 = 12.0;

  /// 16dp.
  static const double space16 = 16.0;

  /// 24dp.
  static const double space24 = 24.0;

  /// 32dp.
  static const double space32 = 32.0;

  /// 48dp.
  static const double space48 = 48.0;

  // ─── Border radius ────────────────────────────────────────────────────────

  /// 4dp — chips, cells.
  static const double radiusSmall = 4.0;

  /// 8dp — buttons, fields.
  static const double radiusDefault = 8.0;

  /// 12dp — cards, dialogs.
  static const double radiusCard = 12.0;

  /// 16dp — sheets.
  static const double radiusLarge = 16.0;

  // ─── Touch targets ────────────────────────────────────────────────────────

  /// The shop-floor minimum. Never shrink this for a denser desktop layout.
  static const double minTouchTarget = 48.0;

  /// The height of a single-line text or dropdown field.
  static const double singleLineFieldHeight = 56.0;

  /// The focus ring's width, in dp. One treatment, everywhere.
  static const double focusRingWidth = 4.0;

  /// A hairline, in dp.
  static const double hairlineWidth = 1.0;

  /// The accent rule down the leading edge of a toast — thick enough to read
  /// as a deliberate stripe rather than a heavy border.
  static const double accentRuleWidth = 4.0;

  // ─── Page layout (ported — Luxe has no equivalent) ────────────────────────

  /// `--measure`: the widest a page's content column ever gets.
  static const double measure = 1200.0;

  /// `--gut` lower bound.
  static const double gutterMin = 16.0;

  /// `--gut` upper bound.
  static const double gutterMax = 40.0;

  /// `--gut` proportion of the viewport width.
  static const double gutterRatio = 0.04;

  // ─── Breakpoints ──────────────────────────────────────────────────────────

  /// Upper bound of the compact (phone) band.
  static const double compactBreakpoint = 600.0;

  /// Lower bound of the expanded (desktop) band.
  static const double expandedBreakpoint = 900.0;

  // ─── Font sizes ───────────────────────────────────────────────────────────

  /// 22 — the page-level scale.
  static const double fontDisplay = 22.0;

  /// 18 — a section.
  static const double fontTitle = 18.0;

  /// 16 — a subsection, a control.
  static const double fontSubtitle = 16.0;

  /// 14 — prose, table cells.
  static const double fontBody = 14.0;

  /// 13 — a form label.
  static const double fontLabel = 13.0;

  /// 12 — a mono caption naming a value.
  static const double fontCaption = 12.0;

  /// Tracking on the mono uppercase caption; it needs the air.
  static const double captionLetterSpacing = 0.8;
}
