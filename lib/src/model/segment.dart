import 'reference.dart';

/// An editor content segment: either a run of plain [text] or a reference
/// token ([ref]). Mirrors the React editor segment shape
/// `{ kind:'text', text } | { kind:'ref', ref }`.
class ComposerSegment {
  const ComposerSegment.text(this.text) : ref = null, kind = 'text';
  const ComposerSegment.ref(this.ref) : text = '', kind = 'ref';

  final String kind;
  final String text;
  final ComposerReference? ref;

  bool get isText => kind == 'text';
  bool get isRef => kind == 'ref';
}
