import 'package:intl/intl.dart';

/// 25000 -> "25 000 so'm"
String formatSom(num amount) {
  final f = NumberFormat.decimalPattern('en_US');
  final text = f.format(amount).replaceAll(',', ' ');
  return "$text so'm";
}