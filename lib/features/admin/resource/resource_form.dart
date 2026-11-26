import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../repositories/admin_repository.dart';
import '../admin_providers.dart';
import 'admin_resource.dart';

/// Resurs yozuvini yaratish yoki tahrirlash oynasi.
class ResourceForm extends ConsumerStatefulWidget {
  const ResourceForm({super.key, required this.resource, this.row});

  final AdminResource resource;
  final DbRow? row;

  @override
  ConsumerState<ResourceForm> createState() => _ResourceFormState();
}

class _ResourceFormState extends ConsumerState<ResourceForm> {
  final _form = GlobalKey<FormState>();
  final _text = <String, TextEditingController>{};

  /// boolean, choice va reference qiymatlari.
  final _values = <String, Object?>{};
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.row == null;

  static bool _isTyped(FieldType t) => const {
    FieldType.text,
    FieldType.multiline,
    FieldType.integer,
    FieldType.decimal,
    FieldType.date,
  }.contains(t);

  @override
  void initState() {
    super.initState();
    for (final f in widget.resource.fields) {
      final value = _isNew ? f.defaultValue : widget.row![f.key];
      if (_isTyped(f.type)) {
        _text[f.key] = TextEditingController(text: value?.toString() ?? '');
      } else if (f.type == FieldType.boolean) {
        _values[f.key] = value as bool? ?? false;
      } else {
        _values[f.key] = value;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final values = <String, dynamic>{};
    for (final f in widget.resource.fields) {
      if (!_isNew && f.createOnly) continue;
      final value = _isTyped(f.type)
          ? f.parse(_text[f.key]!.text)
          : _values[f.key];
      // Yangi yozuvda bo'sh maydon yuborilmaydi: bazadagi standart qiymat qoladi.
      if (_isNew && value == null) continue;
      values[f.key] = value;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (_isNew) {
        await repo.insert(widget.resource.table, values);
      } else {
        await repo.update(
          widget.resource.table,
          widget.row!['id'] as Object,
          values,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(e);
        });
      }
    }
  }

  Future<void> _pickDate(ResourceField f) async {
    final current = DateTime.tryParse(_text[f.key]!.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _text[f.key]!.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Widget _field(ResourceField f) {
    final enabled = _isNew || !f.createOnly;
    final label = f.required ? '${f.label} *' : f.label;

    switch (f.type) {
      case FieldType.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: _values[f.key] as bool,
          onChanged: enabled
              ? (v) => setState(() => _values[f.key] = v)
              : null,
        );
      case FieldType.choice:
        return _dropdown(f, label, enabled, f.options);
      case FieldType.reference:
        final source = f.reference!;
        final rows = ref.watch(adminTableProvider(source.query));
        return rows.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => Text(friendlyError(e)),
          data: (list) => _dropdown(f, label, enabled, {
            for (final r in list)
              // O'ziga o'zi ota bo'la olmaydi.
              if (!(source.table == widget.resource.table &&
                  r['id'] == widget.row?['id']))
                r[source.valueColumn] as String: source.labelOf(r),
          }),
        );
      case FieldType.text:
      case FieldType.multiline:
      case FieldType.integer:
      case FieldType.decimal:
      case FieldType.date:
        final numeric =
            f.type == FieldType.integer || f.type == FieldType.decimal;
        return TextFormField(
          controller: _text[f.key],
          enabled: enabled,
          minLines: f.type == FieldType.multiline ? 3 : 1,
          maxLines: f.type == FieldType.multiline ? 5 : 1,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: f.hint,
            suffixIcon: f.type == FieldType.date
                ? IconButton(
                    tooltip: 'Sanani tanlash',
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    onPressed: () => _pickDate(f),
                  )
                : null,
          ),
          validator: (v) => f.validate(v ?? ''),
        );
    }
  }

  Widget _dropdown(
    ResourceField f,
    String label,
    bool enabled,
    Map<String, String> options,
  ) {
    final current = _values[f.key];
    return DropdownButtonFormField<String>(
      initialValue: options.containsKey(current) ? current as String : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (!f.required)
          const DropdownMenuItem(value: null, child: Text('—')),
        for (final o in options.entries)
          DropdownMenuItem(value: o.key, child: Text(o.value)),
      ],
      onChanged: enabled ? (v) => _values[f.key] = v : null,
      validator: (v) =>
          f.required && v == null ? '${f.label} tanlanishi shart' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? widget.resource.createLabel : 'Tahrirlash'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in widget.resource.fields)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _field(f),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Saqlash'),
        ),
      ],
    );
  }
}
