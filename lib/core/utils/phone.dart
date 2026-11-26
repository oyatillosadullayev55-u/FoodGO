import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Telefon terish oynasini ochadi; imkoni bo'lmasa raqamni nusxalaydi.
Future<void> callPhone(BuildContext context, String? phone) async {
  final messenger = ScaffoldMessenger.of(context);
  final number = (phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
  if (number.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Telefon raqami ko'rsatilmagan")),
    );
    return;
  }
  try {
    if (await launchUrl(Uri(scheme: 'tel', path: number))) return;
  } catch (_) {
    // Quyida raqam nusxalanadi
  }
  await Clipboard.setData(ClipboardData(text: number));
  messenger.showSnackBar(SnackBar(content: Text('Raqam nusxalandi: $number')));
}
