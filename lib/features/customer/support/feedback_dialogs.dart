import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../marketplace/marketplace_providers.dart';

/// Yetkazilgan buyurtma yoki yakunlangan xizmatni baholash.
Future<void> showReviewDialog(
  BuildContext context, {
  String? orderId,
  String? serviceRequestId,
}) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) =>
        _ReviewDialog(orderId: orderId, serviceRequestId: serviceRequestId),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bahoingiz uchun rahmat!')),
    );
  }
}

/// Buyurtma yoki xizmat bo'yicha shikoyat (Super Admin ko'rib chiqadi).
Future<void> showComplaintDialog(
  BuildContext context, {
  String? orderId,
  String? serviceRequestId,
}) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) =>
        _ComplaintDialog(orderId: orderId, serviceRequestId: serviceRequestId),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shikoyat yuborildi. Javob Xabarlar bo\'limiga keladi.'),
      ),
    );
  }
}

class _ReviewDialog extends ConsumerStatefulWidget {
  const _ReviewDialog({this.orderId, this.serviceRequestId});

  final String? orderId;
  final String? serviceRequestId;

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(marketplaceRepositoryProvider)
          .submitReview(
            rating: _rating,
            comment: _comment.text.trim(),
            orderId: widget.orderId,
            serviceRequestId: widget.serviceRequestId,
          );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Baholang'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i yulduz',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 32,
                      color: AppColors.accentGold,
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _comment,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Izoh (ixtiyoriy)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _saving ? null : _send,
          child: const Text('Yuborish'),
        ),
      ],
    );
  }
}

class _ComplaintDialog extends ConsumerStatefulWidget {
  const _ComplaintDialog({this.orderId, this.serviceRequestId});

  final String? orderId;
  final String? serviceRequestId;

  @override
  ConsumerState<_ComplaintDialog> createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends ConsumerState<_ComplaintDialog> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_subject.text.trim().isEmpty || _body.text.trim().isEmpty) {
      setState(() => _error = 'Mavzu va tafsilotni yozing');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(marketplaceRepositoryProvider)
          .createComplaint(
            subject: _subject.text,
            body: _body.text,
            orderId: widget.orderId,
            serviceRequestId: widget.serviceRequestId,
          );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shikoyat'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _subject,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Mavzu'),
              ),
              TextField(
                controller: _body,
                maxLines: 5,
                minLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Nima bo\'ldi?'),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _saving ? null : _send,
          child: const Text('Yuborish'),
        ),
      ],
    );
  }
}
