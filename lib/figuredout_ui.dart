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

// ─── Charts ─────────────────────────────────────────────────────────────────
export 'src/charts/fo_chart_shell.dart';
export 'src/charts/fo_chart_theme.dart';
export 'src/charts/fo_charts.dart';

// ─── Patterns ───────────────────────────────────────────────────────────────
export 'src/patterns/fo_data_table.dart';
export 'src/patterns/fo_description_list.dart';
export 'src/patterns/fo_detail_table.dart';
export 'src/patterns/fo_dialog.dart';
export 'src/patterns/fo_empty_state.dart';
export 'src/patterns/fo_entity_picker.dart';
export 'src/patterns/fo_filter_bar.dart';
export 'src/patterns/fo_form_actions.dart';
export 'src/patterns/fo_form_presenter.dart';
export 'src/patterns/fo_form_scope.dart';
export 'src/patterns/fo_form_section.dart';
export 'src/patterns/fo_form_surface.dart';
export 'src/patterns/fo_form_validation.dart';
export 'src/patterns/fo_info_banner.dart';
export 'src/patterns/fo_page_header.dart';
export 'src/patterns/fo_pagination_bar.dart';
export 'src/patterns/fo_responsive_tile_grid.dart';
export 'src/patterns/fo_scaffold.dart';
export 'src/patterns/fo_seam_grid.dart';
export 'src/patterns/fo_stat_card.dart';
export 'src/patterns/fo_text_prompt.dart';
export 'src/patterns/fo_toast.dart';

// ─── Primitives ─────────────────────────────────────────────────────────────
export 'src/primitives/fo_badge.dart';
export 'src/primitives/fo_boolean_cell.dart';
export 'src/primitives/fo_button.dart';
export 'src/primitives/fo_card.dart';
export 'src/primitives/fo_dropdown_field.dart';
export 'src/primitives/fo_focus_ring.dart';
export 'src/primitives/fo_hint.dart';
export 'src/primitives/fo_overlay_surface.dart';
export 'src/primitives/fo_section_header.dart';
export 'src/primitives/fo_section_surface.dart';
export 'src/primitives/fo_skeleton.dart';
export 'src/primitives/fo_spinner.dart';
export 'src/primitives/fo_status_chip.dart';
export 'src/primitives/fo_text_field.dart';

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
