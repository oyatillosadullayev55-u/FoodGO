import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../repositories/storage_repository.dart';
import '../errors/error_mapper.dart';
import '../theme/app_colors.dart';

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepository(ref.watch(supabaseProvider)),
);

/// Galereyadan rasm tanlaydi, yuklaydi va URL'ni [onChanged] orqali beradi.
/// Rasm olib tashlansa, [onChanged] bo'sh satr ('') bilan chaqiriladi.
class ImagePickerField extends ConsumerStatefulWidget {
  const ImagePickerField({
    super.key,
    required this.restaurantId,
    required this.onChanged,
    this.initialUrl,
  });

  final String restaurantId;
  final String? initialUrl;
  final ValueChanged<String> onChanged;

  @override
  ConsumerState<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends ConsumerState<ImagePickerField> {
  String? _url;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = widget.initialUrl;
    _url = (u == null || u.isEmpty) ? null : u;
  }

  Future<void> _pick() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() => _busy = true);
      final url = await ref
          .read(storageRepositoryProvider)
          .uploadProductImage(restaurantId: widget.restaurantId, file: file);
      if (!mounted) return;
      setState(() => _url = url);
      widget.onChanged(url);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove() {
    setState(() => _url = null);
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pick,
          child: Container(
            height: 160,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.greyLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.borderLight,
              ),
            ),
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : _url == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 36, color: AppColors.grey),
                          SizedBox(height: 6),
                          Text('Rasm tanlash',
                              style: TextStyle(color: AppColors.grey)),
                        ],
                      )
                    : Image.network(
                        _url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_rounded,
                              color: AppColors.grey),
                        ),
                      ),
          ),
        ),
        if (_url != null && !_busy)
          Row(
            children: [
              TextButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Almashtirish'),
              ),
              TextButton.icon(
                onPressed: _remove,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text("O'chirish"),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
      ],
    );
  }
}
