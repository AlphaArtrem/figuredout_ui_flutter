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
export 'src/patterns/fo_action_bar.dart';
export 'src/patterns/fo_attachment_grid.dart';
export 'src/patterns/fo_attention_list.dart';
export 'src/patterns/fo_capacity_grid.dart';
export 'src/patterns/fo_change_diff.dart';
export 'src/patterns/fo_checklist.dart';
export 'src/patterns/fo_consequence_list.dart';
export 'src/patterns/fo_data_table.dart';
export 'src/patterns/fo_date_range.dart';
export 'src/patterns/fo_description_list.dart';
export 'src/patterns/fo_detail_table.dart';
export 'src/patterns/fo_dialog.dart';
export 'src/patterns/fo_done_state.dart';
export 'src/patterns/fo_empty_state.dart';
export 'src/patterns/fo_entity_picker.dart';
export 'src/patterns/fo_entry_list_editor.dart';
export 'src/patterns/fo_filter_bar.dart';
export 'src/patterns/fo_form_actions.dart';
export 'src/patterns/fo_form_presenter.dart';
export 'src/patterns/fo_form_scope.dart';
export 'src/patterns/fo_form_section.dart';
export 'src/patterns/fo_form_surface.dart';
export 'src/patterns/fo_form_validation.dart';
export 'src/patterns/fo_guide.dart';
export 'src/patterns/fo_help_guide.dart';
export 'src/patterns/fo_info_banner.dart';
export 'src/patterns/fo_list_group.dart';
export 'src/patterns/fo_matrix_cells.dart';
export 'src/patterns/fo_matrix_table.dart';
export 'src/patterns/fo_metric_card.dart';
export 'src/patterns/fo_outbox_item.dart';
export 'src/patterns/fo_page_header.dart';
export 'src/patterns/fo_page_state.dart';
export 'src/patterns/fo_pagination_bar.dart';
export 'src/patterns/fo_print_preview.dart';
export 'src/patterns/fo_quantity_matrix.dart';
export 'src/patterns/fo_reason_field.dart';
export 'src/patterns/fo_responsive_tile_grid.dart';
export 'src/patterns/fo_scaffold.dart';
export 'src/patterns/fo_scan.dart';
export 'src/patterns/fo_seam_grid.dart';
export 'src/patterns/fo_search_palette.dart';
export 'src/patterns/fo_shell_app_bar.dart';
export 'src/patterns/fo_shell_scaffold.dart';
export 'src/patterns/fo_shortfall_card.dart';
export 'src/patterns/fo_side_panel.dart';
export 'src/patterns/fo_size_count.dart';
export 'src/patterns/fo_stage_rail.dart';
export 'src/patterns/fo_stat_card.dart';
export 'src/patterns/fo_status_tabs.dart';
export 'src/patterns/fo_step_flow.dart';
export 'src/patterns/fo_text_prompt.dart';
export 'src/patterns/fo_timeline.dart';
export 'src/patterns/fo_toast.dart';
export 'src/patterns/fo_toolbar.dart';

// ─── Primitives ─────────────────────────────────────────────────────────────
export 'src/primitives/fo_avatar.dart';
export 'src/primitives/fo_badge.dart';
export 'src/primitives/fo_boolean_cell.dart';
export 'src/primitives/fo_button.dart';
export 'src/primitives/fo_card.dart';
export 'src/primitives/fo_choice_group.dart';
export 'src/primitives/fo_colour_swatch.dart';
export 'src/primitives/fo_date_field.dart';
export 'src/primitives/fo_disc.dart';
export 'src/primitives/fo_disclosure.dart';
export 'src/primitives/fo_dropdown_field.dart';
export 'src/primitives/fo_focus_ring.dart';
export 'src/primitives/fo_hint.dart';
export 'src/primitives/fo_icon_button.dart';
export 'src/primitives/fo_key_hint.dart';
export 'src/primitives/fo_number_field.dart';
export 'src/primitives/fo_overlay_surface.dart';
export 'src/primitives/fo_pin_pad.dart';
export 'src/primitives/fo_progress_bar.dart';
export 'src/primitives/fo_proportion_bar.dart';
export 'src/primitives/fo_section_header.dart';
export 'src/primitives/fo_section_surface.dart';
export 'src/primitives/fo_segmented_control.dart';
export 'src/primitives/fo_skeleton.dart';
export 'src/primitives/fo_spinner.dart';
export 'src/primitives/fo_status_chip.dart';
export 'src/primitives/fo_switch_tile.dart';
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
