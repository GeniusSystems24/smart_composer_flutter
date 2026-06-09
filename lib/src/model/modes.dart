import 'triggers.dart';

/// Validation rules attached to a mode. All optional; mirrors the React
/// `mode.validation` object.
class ValidationRules {
  const ValidationRules({
    this.maxLength,
    this.requireText = false,
    this.maxAttachments,
    this.requireReferenceType,
    this.allowedReferenceTypes,
  });

  final int? maxLength;
  final bool requireText;
  final int? maxAttachments;
  final List<String>? requireReferenceType;
  final List<String>? allowedReferenceTypes;
}

/// A mode preset. A mode only configures: placeholder, which triggers are live,
/// which toolbar buttons show, access options, submit copy and validation. The
/// core editor is identical across all of them. Mirrors `SC.MODES` entries.
class ComposerMode {
  const ComposerMode({
    required this.id,
    required this.label,
    required this.icon,
    required this.placeholder,
    required this.triggers,
    required this.toolbar,
    this.access = false,
    this.defaultAccess,
    this.submitLabel = 'Send',
    this.submitIcon = 'arrow-up',
    this.validation = const ValidationRules(),
    this.searchProvider,
  });

  final String id;
  final String label;
  final String icon;
  final String placeholder;
  final List<String> triggers;
  final List<String> toolbar;
  final bool access;
  final String? defaultAccess;
  final String submitLabel;
  final String submitIcon;
  final ValidationRules validation;
  final SearchProvider? searchProvider;

  ComposerMode copyWith({
    String? placeholder,
    List<String>? triggers,
    List<String>? toolbar,
    SearchProvider? searchProvider,
    ValidationRules? validation,
  }) {
    return ComposerMode(
      id: id,
      label: label,
      icon: icon,
      placeholder: placeholder ?? this.placeholder,
      triggers: triggers ?? this.triggers,
      toolbar: toolbar ?? this.toolbar,
      access: access,
      defaultAccess: defaultAccess,
      submitLabel: submitLabel,
      submitIcon: submitIcon,
      validation: validation ?? this.validation,
      searchProvider: searchProvider ?? this.searchProvider,
    );
  }
}

/// The built-in mode presets. Mirrors `SC.MODES` 1:1.
class ComposerModes {
  ComposerModes._();

  static const List<String> _tAll = ['@', '#', '/', '\$', ':', 'file:', 'path:'];

  static const aiPrompt = ComposerMode(
    id: 'aiPrompt',
    label: 'AI Prompt',
    icon: 'sparkles',
    placeholder: 'Ask anything — type @ to mention, : for tools, / for commands, # to reference…',
    triggers: _tAll,
    toolbar: ['attach', 'reference', 'command', 'model', 'access', 'spacer', 'send'],
    access: true,
    defaultAccess: 'askBeforeAction',
    submitLabel: 'Run',
    submitIcon: 'arrow-up',
    validation: ValidationRules(maxLength: 4000),
  );

  static const search = ComposerMode(
    id: 'search',
    label: 'Search',
    icon: 'search',
    placeholder: 'Search across everything — @ people, # records, \$ accounts…',
    triggers: ['@', '#', '\$', ':'],
    toolbar: ['reference', 'spacer', 'send'],
    submitLabel: 'Search',
    submitIcon: 'search',
  );

  static const command = ComposerMode(
    id: 'command',
    label: 'Command',
    icon: 'terminal',
    placeholder: 'Type / to run a command…',
    triggers: ['/'],
    toolbar: ['command', 'spacer', 'send'],
    submitLabel: 'Execute',
    submitIcon: 'corner-down-left',
    validation: ValidationRules(requireReferenceType: ['command']),
  );

  static const note = ComposerMode(
    id: 'note',
    label: 'Note',
    icon: 'notebook-pen',
    placeholder: 'Write a note — @ to mention, file: to attach a path…',
    triggers: ['@', '#', 'file:', 'path:'],
    toolbar: ['attach', 'reference', 'spacer', 'send'],
    submitLabel: 'Save Note',
    submitIcon: 'check',
    validation: ValidationRules(requireText: true, maxLength: 2000),
  );

  static const comment = ComposerMode(
    id: 'comment',
    label: 'Comment',
    icon: 'message-square',
    placeholder: 'Add a comment — @ to mention someone…',
    triggers: ['@'],
    toolbar: ['attach', 'spacer', 'send'],
    submitLabel: 'Comment',
    submitIcon: 'arrow-up',
    validation: ValidationRules(requireText: true, maxLength: 1000),
  );

  static const taskDescription = ComposerMode(
    id: 'taskDescription',
    label: 'Task',
    icon: 'square-check-big',
    placeholder: 'Describe the task — @ to assign, /due to set a date, # to link…',
    triggers: ['@', '#', '/'],
    toolbar: ['attach', 'reference', 'assignee', 'spacer', 'send'],
    submitLabel: 'Create Task',
    submitIcon: 'plus',
    validation: ValidationRules(requireText: true, maxAttachments: 10),
  );

  static const invoiceNote = ComposerMode(
    id: 'invoiceNote',
    label: 'Invoice Note',
    icon: 'receipt',
    placeholder: 'Add a note to this invoice — \$ for accounts, # to link records…',
    triggers: ['\$', '#', '@'],
    toolbar: ['reference', 'access', 'spacer', 'send'],
    access: true,
    defaultAccess: 'limitedAccess',
    submitLabel: 'Attach Note',
    submitIcon: 'check',
    validation: ValidationRules(
      allowedReferenceTypes: ['invoice', 'payment', 'financialAccount', 'bankAccount', 'transaction', 'report', 'user'],
    ),
  );

  static const financialEntry = ComposerMode(
    id: 'financialEntry',
    label: 'Financial Entry',
    icon: 'wallet',
    placeholder: 'Reference accounts and transactions — type \$ to begin…',
    triggers: ['\$', '#'],
    toolbar: ['reference', 'access', 'spacer', 'send'],
    access: true,
    defaultAccess: 'askBeforeAction',
    submitLabel: 'Post Entry',
    submitIcon: 'corner-down-left',
    validation: ValidationRules(
      requireReferenceType: ['financialAccount', 'bankAccount'],
      allowedReferenceTypes: ['financialAccount', 'bankAccount', 'payment', 'invoice', 'transaction', 'report'],
    ),
  );

  static const message = ComposerMode(
    id: 'message',
    label: 'Message',
    icon: 'send',
    placeholder: 'Message — @ to mention, : for tools, file: to share a path…',
    triggers: ['@', ':', 'file:'],
    toolbar: ['attach', 'reference', 'spacer', 'send'],
    submitLabel: 'Send',
    submitIcon: 'arrow-up',
    validation: ValidationRules(maxAttachments: 6),
  );

  /// Lookup by id (mirrors `SC.MODES[id]`).
  static final Map<String, ComposerMode> byId = {
    'aiPrompt': aiPrompt,
    'search': search,
    'command': command,
    'note': note,
    'comment': comment,
    'taskDescription': taskDescription,
    'invoiceNote': invoiceNote,
    'financialEntry': financialEntry,
    'message': message,
  };
}
