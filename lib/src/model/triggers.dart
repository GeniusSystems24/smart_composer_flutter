import 'dart:async';

import '../model/reference.dart';

/// A search suggestion group returned by a provider.
class SuggestionGroup {
  const SuggestionGroup({required this.group, required this.items});
  final String group;
  final List<ComposerReference> items;
}

/// Signature for a suggestion provider — given a query and the trigger's types,
/// return grouped results. Sync or async (return a Future). Mirrors the React
/// `searchProvider(query, types, opts)` contract.
typedef SearchProvider = FutureOr<List<SuggestionGroup>> Function(
  String query,
  List<String> types,
  Map<String, dynamic> opts,
);

/// A configurable trigger. Each maps a symbol to the reference types it
/// searches, plus menu copy. Word triggers (`file:`, `path:`) set [word].
/// Mirrors `SC.TRIGGERS` entries.
class TriggerConfig {
  const TriggerConfig({
    required this.symbol,
    required this.label,
    required this.hint,
    required this.types,
    this.word = false,
    this.searchProvider,
    this.tokenBuilder,
  });

  final String symbol;
  final String label;
  final String hint;
  final List<String> types;
  final bool word;

  /// Optional per-trigger provider that overrides the default search.
  final SearchProvider? searchProvider;

  /// Optional transform of the chosen reference before it is inserted.
  final ComposerReference Function(ComposerReference ref)? tokenBuilder;

  TriggerConfig copyWith({SearchProvider? searchProvider}) => TriggerConfig(
        symbol: symbol,
        label: label,
        hint: hint,
        types: types,
        word: word,
        searchProvider: searchProvider ?? this.searchProvider,
        tokenBuilder: tokenBuilder,
      );
}

/// The trigger registry. Mirrors `SC.TRIGGERS` + `SC.TRIGGER_KEYS`.
class Triggers {
  Triggers._();

  static final Map<String, TriggerConfig> all = {
    '@': const TriggerConfig(symbol: '@', label: 'Mention', hint: 'people & teams', types: ['user', 'member', 'team', 'club']),
    '#': const TriggerConfig(symbol: '#', label: 'Reference', hint: 'tasks, invoices, reports', types: ['task', 'project', 'invoice', 'report']),
    '/': const TriggerConfig(symbol: '/', label: 'Command', hint: 'commands & actions', types: ['command']),
    '\$': const TriggerConfig(symbol: '\$', label: 'Financial', hint: 'accounts, payments, txns', types: ['financialAccount', 'bankAccount', 'payment', 'invoice', 'transaction']),
    ':': const TriggerConfig(symbol: ':', label: 'Tools', hint: 'AI tools & skills', types: ['tool', 'skill']),
    'file:': const TriggerConfig(symbol: 'file:', word: true, label: 'File path', hint: 'files', types: ['file', 'document', 'image', 'video']),
    'path:': const TriggerConfig(symbol: 'path:', word: true, label: 'Path', hint: 'folders & files', types: ['folder', 'file']),
  };

  /// Trigger keys sorted longest-first so multi-char word triggers win the
  /// prefix match (mirrors `SC.TRIGGER_KEYS`).
  static List<String> get keys {
    final k = all.keys.toList();
    k.sort((a, b) => b.length.compareTo(a.length));
    return k;
  }
}
