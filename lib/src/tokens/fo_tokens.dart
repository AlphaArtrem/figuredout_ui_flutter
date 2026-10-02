import 'package:flutter/material.dart';

/// Raw design tokens — the single source of truth for every literal value in
/// the system, and the **only** file allowed to hold one.
///
/// Colours are ported verbatim from `@figuredout/ui-web`'s
/// `styles/tokens.css` (last synced with its `569b4a2`, the FiguredoutAI
/// palette). If a value here looks wrong, fix it in the web package first so
/// the two stay in step. `rgba(r, g, b, a)` becomes
/// `Color(0xAARRGGBB)` with `AA = round(a * 255)`.
///
/// Spacing and touch metrics are *not* ported from the web: they are kept from
/// Luxe, because the consuming apps run on shop-floor tablets where a 48dp
/// touch target and a 56dp field are load-bearing. Corner radii are the web
/// package's since 0.7.0 — nothing about a gloved finger depends on them.
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
  //
  // The palette is FiguredoutAI's — ink #030A0E, sky #90C2E7, peak #C9E4F5,
  // paper #F0EDEF, with deep teal, green, amber and terracotta supporting — as
  // `@figuredout/ui-web` adopted it in `60926da`. Light mode is the same hues
  // re-levelled onto a paper ground, which is why `primary` here is the deep
  // teal and not the sky: sky on a pale ground is 1.8:1.

  /// Light: the page itself.
  static const Color bg = Color(0xFFEEF2F5);

  /// Light: cards, tables, panels — anything resting on the page.
  static const Color surface = Color(0xFFF7FAFB);

  /// Light: anything lifted — dialog, menu, toast, hovered row, open tile.
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Light: holes — text fields, segmented-control tracks, wells.
  static const Color surfaceSunken = Color(0xFFE2E9EE);

  // ─── Light ink ────────────────────────────────────────────────────────────

  /// Light: primary ink.
  static const Color fg = Color(0xFF030A0E);

  /// Light: secondary ink — supporting prose, captions.
  static const Color fgMuted = Color(0xFF2C3B42);

  /// Light: tertiary ink — the quietest readable step.
  static const Color fgSubtle = Color(0xFF47575F);

  /// Light: hairlines.
  static const Color edge = Color(0xFFD3DEE4);

  /// Light: a hairline that has to be found rather than merely obeyed.
  static const Color edgeStrong = Color(0xFF9DAFB8);

  // ─── Light semantic ───────────────────────────────────────────────────────

  /// Light: the brand hue — the deep teal.
  static const Color primary = Color(0xFF15586B);

  /// Light: primary under a pointer.
  static const Color primaryHover = Color(0xFF0E4353);

  /// Light: ink on [primary] — the brand's paper.
  static const Color primaryFg = Color(0xFFF0EDEF);

  /// Light: `rgba(21, 88, 107, 0.10)`. 0.10 rather than the 0.12 the other
  /// washes use: at 0.12 this teal lightens its own ground enough to pull
  /// `primary` on `primarySoft` under 4.5:1 — the composite a chip makes.
  static const Color primarySoft = Color(0x1A15586B);

  /// Light: `rgba(21, 88, 107, 0.34)` — the one focus treatment.
  static const Color focusRing = Color(0x5715586B);

  /// Light: success.
  static const Color success = Color(0xFF12643A);

  /// Light: `rgba(79, 168, 124, 0.16)`.
  static const Color successSoft = Color(0x294FA87C);

  /// Light: warning.
  static const Color warning = Color(0xFF6D4210);

  /// Light: `rgba(232, 163, 61, 0.18)`.
  static const Color warningSoft = Color(0x2EE8A33D);

  /// Light: danger.
  static const Color danger = Color(0xFF8E2F24);

  /// Light: ink on [danger]. Danger carries its own ink — [primaryFg] is the
  /// ink for PRIMARY, and in dark mode it is a near-black ink, which on a
  /// light terracotta is unreadable.
  static const Color dangerFg = Color(0xFFFDF3F1);

  /// Light: `rgba(212, 100, 90, 0.16)`.
  static const Color dangerSoft = Color(0x29D4645A);

  /// Light: information.
  static const Color info = Color(0xFF1C4B80);

  /// Light: `rgba(144, 194, 231, 0.28)`.
  static const Color infoSoft = Color(0x4790C2E7);

  /// Light: accent.
  static const Color accent = Color(0xFF7A3A1A);

  /// Light: ink on [accent].
  static const Color accentFg = Color(0xFFFDF3F1);

  // ─── Dark surfaces ────────────────────────────────────────────────────────
  // Dark is the canonical scheme: it is the marketing site's own, ink ground
  // and sky primary. The ladder is #010508 → #030A0E → #08171D → #0E2530.

  /// Dark: the page itself.
  static const Color bgDark = Color(0xFF030A0E);

  /// Dark: cards, tables, panels.
  static const Color surfaceDark = Color(0xFF08171D);

  /// Dark: anything lifted.
  static const Color surfaceRaisedDark = Color(0xFF0E2530);

  /// Dark: holes.
  static const Color surfaceSunkenDark = Color(0xFF010508);

  // ─── Dark ink ─────────────────────────────────────────────────────────────

  /// Dark: primary ink.
  static const Color fgDark = Color(0xFFF0EDEF);

  /// Dark: secondary ink.
  static const Color fgMutedDark = Color(0xFFAFB1B4);

  /// Dark: tertiary ink.
  static const Color fgSubtleDark = Color(0xFF8A8F93);

  /// Dark: hairlines.
  static const Color edgeDark = Color(0xFF1E323D);

  /// Dark: a findable hairline.
  static const Color edgeStrongDark = Color(0xFF415F72);

  // ─── Dark semantic ────────────────────────────────────────────────────────

  /// Dark: the brand hue — the sky.
  static const Color primaryDark = Color(0xFF90C2E7);

  /// Dark: primary under a pointer — the peak.
  static const Color primaryHoverDark = Color(0xFFC9E4F5);

  /// Dark: ink on [primaryDark].
  static const Color primaryFgDark = Color(0xFF030A0E);

  /// Dark: `rgba(144, 194, 231, 0.16)`.
  static const Color primarySoftDark = Color(0x2990C2E7);

  /// Dark: `rgba(144, 194, 231, 0.36)`.
  static const Color focusRingDark = Color(0x5C90C2E7);

  /// Dark: success.
  static const Color successDark = Color(0xFF5CBB8B);

  /// Dark: `rgba(79, 168, 124, 0.16)`.
  static const Color successSoftDark = Color(0x294FA87C);

  /// Dark: warning.
  static const Color warningDark = Color(0xFFE8A33D);

  /// Dark: `rgba(232, 163, 61, 0.16)`.
  static const Color warningSoftDark = Color(0x29E8A33D);

  /// Dark: danger.
  static const Color dangerDark = Color(0xFFE2827A);

  /// Dark: ink on [dangerDark].
  static const Color dangerFgDark = Color(0xFF2A0906);

  /// Dark: `rgba(212, 100, 90, 0.18)`.
  static const Color dangerSoftDark = Color(0x2ED4645A);

  /// Dark: information.
  static const Color infoDark = Color(0xFF7FBCD6);

  /// Dark: `rgba(27, 101, 121, 0.40)`.
  static const Color infoSoftDark = Color(0x661B6579);

  /// Dark: accent.
  static const Color accentDark = Color(0xFFC9E4F5);

  /// Dark: ink on [accentDark].
  static const Color accentFgDark = Color(0xFF030A0E);

  // ─── Extra roles, every palette ──────────────────────────────────────────

  /// Light: `rgba(3, 10, 14, 0.25)` — the ring around a garment colour dot,
  /// so Ecru keeps an edge on white.
  static const Color swatchRing = Color(0x40030A0E);

  /// Dark: `rgba(255, 255, 255, 0.35)` — on a dark ground the ring is light,
  /// or Deep Navy and Jet Black dots vanish (1.0–1.4:1 against the surface).
  static const Color swatchRingDark = Color(0x59FFFFFF);

  /// Light: the needs-approval (warning) button's hairline — warning at the
  /// banner's edge strength, 0.32.
  static const Color warningRing = Color(0x526D4210);

  /// Dark: the same, from the dark warning.
  static const Color warningRingDark = Color(0x52E8A33D);

  // ─── Graphite: an alternative dark palette ───────────────────────────────
  // Not the web package's — an app opts into it with
  // `FoTheme.dark(palette: FoDarkPalette.graphite)`. Neutral near-black greys
  // with a slight cool cast; the light theme's teal lifted for a dark ground,
  // so primary is one hue in both modes; status colours keep their true hue
  // on a neutral ground. Chosen by Luxe's owner (canvas `darkthemes.json`,
  // `notes/dark-themes.md`), where the ink/sky dark read poorly on the floor:
  // invisible hairlines, input rings under 3:1, an inverted sunken step.
  // Washes are opaque, not alpha, so a chip reads the same on every surface.

  /// Graphite: the page.
  static const Color bgGraphite = Color(0xFF111315);

  /// Graphite: cards, panels.
  static const Color surfaceGraphite = Color(0xFF1B1E21);

  /// Graphite: lifted — tiles, inputs, dialogs.
  static const Color surfaceRaisedGraphite = Color(0xFF262A2E);

  /// Graphite: holes — tracks, wells. Below the page, as the ladder requires.
  static const Color surfaceSunkenGraphite = Color(0xFF0B0C0D);

  /// Graphite: primary ink.
  static const Color fgGraphite = Color(0xFFF1F3F5);

  /// Graphite: secondary ink.
  static const Color fgMutedGraphite = Color(0xFFC5CCD2);

  /// Graphite: tertiary ink — captions, still 5.8:1 on every surface.
  static const Color fgSubtleGraphite = Color(0xFFA1AAB2);

  /// Graphite: hairlines — 1.5:1 or more on every surface.
  static const Color edgeGraphite = Color(0xFF41474E);

  /// Graphite: a findable hairline — input rings, 3.5:1 or more.
  static const Color edgeStrongGraphite = Color(0xFF757E87);

  /// Graphite: the brand teal, lifted for a dark ground.
  static const Color primaryGraphite = Color(0xFF3CC4C9);

  /// Graphite: primary under a pointer.
  static const Color primaryHoverGraphite = Color(0xFF7FDDE0);

  /// Graphite: ink on [primaryGraphite] — the card colour.
  static const Color primaryFgGraphite = Color(0xFF1B1E21);

  /// Graphite: the primary wash, opaque.
  static const Color primarySoftGraphite = Color(0xFF173A3D);

  /// Graphite: the focus ring — primary at 0.6.
  static const Color focusRingGraphite = Color(0x993CC4C9);

  /// Graphite: success.
  static const Color successGraphite = Color(0xFF5FD394);

  /// Graphite: the success wash, opaque.
  static const Color successSoftGraphite = Color(0xFF183526);

  /// Graphite: warning.
  static const Color warningGraphite = Color(0xFFF2B65A);

  /// Graphite: the warning wash, opaque.
  static const Color warningSoftGraphite = Color(0xFF3A2C14);

  /// Graphite: the needs-approval ring — warning at 0.5.
  static const Color warningRingGraphite = Color(0x80F2B65A);

  /// Graphite: danger.
  static const Color dangerGraphite = Color(0xFFFF8A7D);

  /// Graphite: ink on [dangerGraphite] — the raised colour.
  static const Color dangerFgGraphite = Color(0xFF262A2E);

  /// Graphite: the danger wash, opaque.
  static const Color dangerSoftGraphite = Color(0xFF3F201D);

  /// Graphite: information — blue, kept clear of the teal primary.
  static const Color infoGraphite = Color(0xFF8FB6FF);

  /// Graphite: the info wash, opaque.
  static const Color infoSoftGraphite = Color(0xFF1C2A44);

  /// Graphite: accent — the primary hover, as the dark palette's is.
  static const Color accentGraphite = Color(0xFF7FDDE0);

  /// Graphite: ink on [accentGraphite] — the page colour.
  static const Color accentFgGraphite = Color(0xFF111315);

  /// Graphite: categorical series 1–6 — the palette's own primary and status
  /// hues, then muted ink. Series 6 is *not* the axis ink, unlike the web
  /// package's dark set.
  static const List<Color> chartCategoricalGraphite = <Color>[
    Color(0xFF3CC4C9),
    Color(0xFF5FD394),
    Color(0xFFF2B65A),
    Color(0xFFFF8A7D),
    Color(0xFF8FB6FF),
    Color(0xFFC5CCD2),
  ];

  /// Graphite: `rgba(241, 243, 245, 0.12)`.
  static const Color chartGridGraphite = Color(0x1FF1F3F5);

  /// Graphite: axis tick labels — the subtle ink.
  static const Color chartAxisLabelGraphite = Color(0xFFA1AAB2);

  /// Graphite: a target rule — the strong hairline.
  static const Color chartTargetLineGraphite = Color(0xFF757E87);

  // ─── Charts ───────────────────────────────────────────────────────────────
  // Series hues never carry status meaning; status uses the semantic palette.

  /// Light: categorical series 1–6.
  static const List<Color> chartCategorical = <Color>[
    Color(0xFF15586B),
    Color(0xFF1C4B80),
    Color(0xFF7A3A1A),
    Color(0xFF8E2F24),
    Color(0xFF6D4210),
    Color(0xFF47575F),
  ];

  /// Dark: categorical series 1–6.
  static const List<Color> chartCategoricalDark = <Color>[
    Color(0xFF90C2E7),
    Color(0xFF5CBB8B),
    Color(0xFFE8A33D),
    Color(0xFFE2827A),
    Color(0xFF7FBCD6),
    Color(0xFFAFB1B4),
  ];

  /// Light: the single hue a sequential scale ramps through.
  static const Color chartSequential = Color(0xFF15586B);

  /// Dark: the single hue a sequential scale ramps through.
  static const Color chartSequentialDark = Color(0xFF90C2E7);

  /// Light: `rgba(3, 10, 14, 0.10)`.
  static const Color chartGrid = Color(0x1A030A0E);

  /// Dark: `rgba(240, 237, 239, 0.12)`.
  static const Color chartGridDark = Color(0x1FF0EDEF);

  /// Light: axis tick labels.
  static const Color chartAxisLabel = Color(0xFF47575F);

  /// Dark: axis tick labels.
  static const Color chartAxisLabelDark = Color(0xFFAFB1B4);

  /// Light: `--chart-track` — the unfilled part of a meter: a progress bar's
  /// rest, an empty step. Named apart from the hairline because a track is not
  /// an edge, and the two want to move independently.
  static const Color chartTrack = Color(0xFFE2E9EE);

  /// Dark: `--chart-track`.
  static const Color chartTrackDark = Color(0xFF132C38);

  /// Light: a target/threshold rule on a chart. Flutter-only — the web
  /// package has no equivalent; it tracks [fgSubtle].
  static const Color chartTargetLine = Color(0xFF47575F);

  /// Dark: a target/threshold rule on a chart. Tracks [edgeStrongDark].
  static const Color chartTargetLineDark = Color(0xFF415F72);

  // ─── Elevation ────────────────────────────────────────────────────────────
  // Tinted with the ground's own hue rather than black: a black shadow on a
  // tinted surface greys out the colour beneath it and reads as dirt. Being
  // hue-matched also lets them run at a lower opacity.

  /// Light: `rgba(3, 20, 28, 0.05)`.
  static const Color shadowRaisedNear = Color(0x0D03141C);

  /// Light: `rgba(3, 20, 28, 0.07)`.
  static const Color shadowRaisedFar = Color(0x1203141C);

  /// Light: `rgba(3, 20, 28, 0.07)`.
  static const Color shadowHoverNear = Color(0x1203141C);

  /// Light: `rgba(3, 20, 28, 0.11)`.
  static const Color shadowHoverFar = Color(0x1C03141C);

  /// Light: `rgba(3, 20, 28, 0.08)`.
  static const Color shadowOverlayNear = Color(0x1403141C);

  /// Light: `rgba(3, 20, 28, 0.16)`.
  static const Color shadowOverlayFar = Color(0x2903141C);

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

  /// The scrim behind a dialog, a sheet or a side panel: primary ink at this
  /// strength — the web package's `color-mix(var(--color-fg) 28%)`. Ink rather
  /// than black, so the dark theme's scrim lightens the page instead of
  /// sinking an already-dark ground into a hole.
  static const double scrimOpacity = 0.28;

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

  /// 4dp — cells, a selected table cell, a skeleton line.
  static const double radiusSmall = 4.0;

  /// 10dp — buttons, fields. `--radius-md`, the web package's control radius.
  static const double radiusDefault = 10.0;

  /// 16dp — cards, panels. `--radius-xl`, the web package's `Card`.
  static const double radiusCard = 16.0;

  /// 16dp — dialogs and sheets. The same as [radiusCard] today; named apart
  /// because a lifted surface and a resting one may want to move separately.
  static const double radiusLarge = 16.0;

  /// A pill — `rounded-full`. Status chips and badges: a shape no rectangle
  /// on the page shares, so a status reads as a word and never as a button.
  static const double radiusPill = 999.0;

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
