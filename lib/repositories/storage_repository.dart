import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  StorageRepository(this._client);

  final SupabaseClient _client;
  static const _bucket = 'product-images';

  /// Rasmni yuklaydi va ommaviy URL qaytaradi.
  Future<String> uploadProductImage({
    required String restaurantId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = _extension(file.name);
    final path =
        '$restaurantId/${DateTime.now().microsecondsSinceEpoch}.$ext';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mime(ext)),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? 'jpg' : name.substring(dot + 1).toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp'}.contains(ext) ? ext : 'jpg';
  }

  static String _mime(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
