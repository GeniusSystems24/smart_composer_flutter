import 'package:flutter/material.dart';

/// Resolves a Lucide icon name (as used throughout the React model) to a
/// Material [IconData]. The React app loads Lucide; for Flutter we map the
/// exact names used to their closest Material equivalents so the package has no
/// extra icon-font dependency. Swap this out for a Lucide font package by
/// overriding [ComposerIcons.resolver] if you want pixel-identical glyphs.
class ComposerIcons {
  ComposerIcons._();

  /// Override to plug in a different icon set (e.g. a Lucide font package).
  static IconData Function(String name)? resolver;

  static const IconData fallback = Icons.label_outline;

  static const Map<String, IconData> _map = {
    // entity types
    'user': Icons.person_outline,
    'user-round': Icons.account_circle_outlined,
    'users': Icons.group_outlined,
    'shield': Icons.shield_outlined,
    'file': Icons.insert_drive_file_outlined,
    'folder': Icons.folder_outlined,
    'file-text': Icons.description_outlined,
    'image': Icons.image_outlined,
    'video': Icons.videocam_outlined,
    'receipt': Icons.receipt_long_outlined,
    'credit-card': Icons.credit_card,
    'wallet': Icons.account_balance_wallet_outlined,
    'landmark': Icons.account_balance_outlined,
    'arrow-left-right': Icons.swap_horiz,
    'chart-column': Icons.bar_chart,
    'square-check-big': Icons.check_box_outlined,
    'layers': Icons.layers_outlined,
    'wrench': Icons.build_outlined,
    'sparkles': Icons.auto_awesome_outlined,
    'terminal': Icons.terminal_outlined,
    'link': Icons.link,
    'box': Icons.inventory_2_outlined,
    // access modes
    'shield-check': Icons.verified_user_outlined,
    'shield-question': Icons.gpp_maybe_outlined,
    'shield-off': Icons.gpp_bad_outlined,
    'eye': Icons.visibility_outlined,
    // mode icons
    'search': Icons.search,
    'notebook-pen': Icons.note_alt_outlined,
    'message-square': Icons.chat_bubble_outline,
    'send': Icons.send_outlined,
    // submit icons
    'arrow-up': Icons.arrow_upward,
    'corner-down-left': Icons.keyboard_return,
    'check': Icons.check,
    'plus': Icons.add,
    // toolbar / view
    'at-sign': Icons.alternate_email,
    'slash-square': Icons.code,
    'user-plus': Icons.person_add_alt,
    'chevron-down': Icons.keyboard_arrow_down,
    'brain': Icons.psychology_outlined,
    'zap': Icons.bolt,
    'alert-triangle': Icons.warning_amber_rounded,
    'x': Icons.close,
    'search-x': Icons.search_off,
    'mouse-pointer-click': Icons.ads_click,
    // preview
    'circle-help': Icons.help_outline,
    'lock': Icons.lock_outline,
    'rotate-cw': Icons.refresh,
    // app shell / tabs
    'layout-panel-left': Icons.view_quilt_outlined,
    'layout-grid': Icons.grid_view_outlined,
    'braces': Icons.data_object,
    'mouse-pointer-2': Icons.touch_app_outlined,
    'flask-conical': Icons.science_outlined,
    'book-open': Icons.menu_book_outlined,
    'sun': Icons.light_mode_outlined,
    'moon': Icons.dark_mode_outlined,
    'wand-sparkles': Icons.auto_fix_high,
    'eraser': Icons.cleaning_services_outlined,
    'sliders-horizontal': Icons.tune,
    'activity': Icons.timeline,
    'shapes': Icons.category_outlined,
    // docs
    'database': Icons.storage,
    'cpu': Icons.memory,
    'layout-template': Icons.dashboard_outlined,
    'plus-circle': Icons.add_circle_outline,
    'paintbrush': Icons.brush_outlined,
    'webhook': Icons.webhook,
    'code': Icons.code,
    // drop tab
    'file-down': Icons.file_download_outlined,
    'file-x': Icons.block,
    'download': Icons.download,
    'upload': Icons.upload,
    'grip-vertical': Icons.drag_indicator,
    'check-check': Icons.done_all,
  };

  static IconData resolve(String? name) {
    if (name == null) return fallback;
    if (resolver != null) return resolver!(name);
    return _map[name] ?? fallback;
  }
}
