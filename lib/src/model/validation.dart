import 'attachment.dart';
import 'modes.dart';
import 'reference.dart';
import 'reference_registry.dart';

/// A single validation error. Mirrors `{ code, message, refId }`.
class ValidationError {
  const ValidationError({required this.code, required this.message, this.refId});
  final String code;
  final String message;
  final String? refId;
}

/// Result of validation. Mirrors `ComposerValidationResult`.
class ComposerValidationResult {
  const ComposerValidationResult({required this.valid, required this.errors});
  final bool valid;
  final List<ValidationError> errors;

  static const ok = ComposerValidationResult(valid: true, errors: []);
}

/// Pure validation. Mirrors `SC.validate(value, rules)` exactly, including the
/// entity-state checks (error → unavailable, disabled → archived).
class ComposerValidator {
  ComposerValidator._();

  static ComposerValidationResult validate({
    required String text,
    required List<ComposerReference> references,
    required List<ComposerAttachment> attachments,
    required ValidationRules rules,
  }) {
    final refs = references;
    final atts = attachments;
    final trimmed = text.trim();
    final errors = <ValidationError>[];

    if (rules.requireText && trimmed.isEmpty && refs.isEmpty) {
      errors.add(const ValidationError(code: 'requiredText', message: 'Enter some text or add a reference.'));
    }
    if (rules.maxLength != null && text.length > rules.maxLength!) {
      errors.add(ValidationError(code: 'maxTextLength', message: 'Exceeds ${rules.maxLength} characters.'));
    }
    if (rules.maxAttachments != null && atts.length > rules.maxAttachments!) {
      errors.add(ValidationError(code: 'maxAttachments', message: 'At most ${rules.maxAttachments} attachments.'));
    }
    if (rules.requireReferenceType != null) {
      final need = rules.requireReferenceType!;
      final ok = refs.any((r) => need.contains(r.type));
      if (!ok) {
        final labels = need.map((t) => ReferenceRegistry.get(t).label).join(' or ');
        errors.add(ValidationError(code: 'requiredReferenceType', message: 'Add at least one $labels.'));
      }
    }
    if (rules.allowedReferenceTypes != null) {
      for (final r in refs) {
        if (!rules.allowedReferenceTypes!.contains(r.type)) {
          errors.add(ValidationError(
            code: 'forbiddenReferenceType',
            message: '${ReferenceRegistry.get(r.type).label} not allowed here.',
            refId: r.id,
          ));
        }
      }
    }
    // entity-state validation (deleted user, archived task, unavailable account…)
    for (final r in refs) {
      if (r.state == 'error') {
        errors.add(ValidationError(code: 'invalidReference', message: '${r.title} is unavailable.', refId: r.id));
      }
      if (r.state == 'disabled') {
        errors.add(ValidationError(code: 'archivedReference', message: '${r.title} is archived.', refId: r.id));
      }
    }

    return ComposerValidationResult(valid: errors.isEmpty, errors: errors);
  }
}
