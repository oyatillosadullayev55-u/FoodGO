/// Jadval boshqaruvini tavsiflash: bitta sahifa barcha oddiy modullarga yetadi.
library;

import 'package:flutter/material.dart';

import '../../../repositories/admin_repository.dart';
import '../admin_providers.dart';

enum FieldType {
  text,
  multiline,
  integer,
  decimal,
  boolean,
  date,
  choice,
  reference,
}

/// Boshqa jadvaldan tanlanadigan qiymat.
class Reference {
  const Reference(
    this.table, {
    required this.labelColumns,
    this.valueColumn = 'id',
  });

  final String table;
  final String valueColumn;

  /// Birinchi bo'sh bo'lmagan ustun yozuv sifatida ko'rsatiladi.
  final List<String> labelColumns;

  TableQuery get query =>
      tableQuery(table, orderBy: labelColumns.first, ascending: true);

  String labelOf(DbRow row) {
    for (final column in labelColumns) {
      final v = row[column]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return row[valueColumn].toString();
  }
}

class ResourceField {
  const ResourceField(
    this.key,
    this.label, {
    this.type = FieldType.text,
    this.required = false,
    this.options = const {},
    this.reference,
    this.defaultValue,
    this.createOnly = false,
    this.min,
    this.max,
    this.hint,
  });

  final String key;
  final String label;
  final FieldType type;
  final bool required;

  /// choice uchun: qiymat → yozuv.
  final Map<String, String> options;
  final Reference? reference;
  final Object? defaultValue;

  /// Yaratilgandan keyin o'zgartirilmaydi.
  final bool createOnly;
  final num? min;
  final num? max;
  final String? hint;

  /// Matn maydonidagi qiymatni bazaga mos turga o'giradi.
  Object? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return switch (type) {
      FieldType.integer => int.tryParse(text),
      FieldType.decimal => num.tryParse(text.replaceAll(',', '.')),
      _ => text,
    };
  }

  /// Xato matni yoki null.
  String? validate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return required ? '$label kiritilishi shart' : null;
    if (type == FieldType.integer || type == FieldType.decimal) {
      final n = parse(text) as num?;
      if (n == null) return "Son noto'g'ri";
      if (min != null && n < min!) return 'Eng kami $min';
      if (max != null && n > max!) return "Eng ko'pi $max";
    }
    if (type == FieldType.date && !_isDate(text)) {
      return 'Sana: YYYY-MM-DD';
    }
    return null;
  }

  static bool _isDate(String text) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return false;
    final d = DateTime.tryParse(text);
    // DateTime.parse "2026-02-31" ni martga suradi, buni rad etamiz.
    return d != null && d.toIso8601String().startsWith(text);
  }
}

class AdminResource {
  const AdminResource({
    required this.table,
    required this.title,
    required this.icon,
    required this.fields,
    required this.itemTitle,
    this.itemSubtitle,
    this.orderBy = 'created_at',
    this.ascending = false,
    this.canDelete = true,
    this.broadcastOnly = false,
    this.createLabel = "Qo'shish",
  });

  final String table;
  final String title;
  final IconData icon;
  final List<ResourceField> fields;
  final String Function(DbRow) itemTitle;
  final String Function(DbRow)? itemSubtitle;
  final String orderBy;
  final bool ascending;
  final bool canDelete;

  /// Faqat umumiy (user_id bo'sh) yozuvlar.
  final bool broadcastOnly;
  final String createLabel;

  TableQuery get query => tableQuery(
    table,
    orderBy: orderBy,
    ascending: ascending,
    broadcastOnly: broadcastOnly,
  );
}
