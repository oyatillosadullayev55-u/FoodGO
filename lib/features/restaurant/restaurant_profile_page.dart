import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_map.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/image_picker_field.dart';
import '../../models/restaurant.dart';
import '../delivery/delivery_providers.dart';

class RestaurantProfilePage extends ConsumerStatefulWidget {
  const RestaurantProfilePage({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  ConsumerState<RestaurantProfilePage> createState() => _RestaurantProfilePageState();
}

class _RestaurantProfilePageState extends ConsumerState<RestaurantProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _address;
  late String _image;
  TimeOfDay? _open;
  TimeOfDay? _close;
  LatLng? _location;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    _name = TextEditingController(text: r.name);
    _desc = TextEditingController(text: r.description ?? '');
    _address = TextEditingController(text: r.address ?? '');
    _image = r.imageUrl ?? '';
    _open = _parse(r.openTime);
    _close = _parse(r.closeTime);
    _location = r.location;
    _active = r.isActive;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _address.dispose();
    super.dispose();
  }

  static TimeOfDay? _parse(String? s) {
    if (s == null || s.length < 5) return null;
    final h = int.tryParse(s.substring(0, 2));
    final m = int.tryParse(s.substring(3, 5));
    return (h == null || m == null) ? null : TimeOfDay(hour: h, minute: m);
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool open}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (open ? _open : _close) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t == null) return;
    setState(() {
      if (open) {
        _open = t;
      } else {
        _close = t;
      }
    });
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.length < 2) return _snack('Restoran nomini kiriting');

    setState(() => _saving = true);
    try {
      if (_active) {
        if (_location == null) {
          _snack('Faollashtirish uchun xaritada joylashuvni belgilang');
          setState(() => _saving = false);
          return;
        }
        final products =
            await ref.read(restaurantProductsProvider(widget.restaurant.id).future);
        if (!products.any((p) => p.isAvailable)) {
          _snack("Faollashtirish uchun menyuga kamida bitta taom qo'shing");
          setState(() => _saving = false);
          return;
        }
      }

      await ref.read(deliveryRepositoryProvider).updateRestaurant(widget.restaurant.id, {
        'name': name,
        'description': _desc.text.trim(),
        'address': _address.text.trim(),
        'image_url': _image.isEmpty ? null : _image,
        'open_time': _open == null ? null : _fmt(_open!),
        'close_time': _close == null ? null : _fmt(_close!),
        'lat': _location?.latitude,
        'lng': _location?.longitude,
        'is_active': _active,
      });
      ref.invalidate(myRestaurantsProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack(friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restoran ma'lumotlari", style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ContentFrame(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ImagePickerField(
              restaurantId: widget.restaurant.id,
              initialUrl: _image,
              onChanged: (url) => _image = url,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Restoran nomi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Tavsif'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Manzil'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(open: true),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(_open == null ? 'Ochilish vaqti' : 'Ochiladi: ${_fmt(_open!)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(open: false),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(_close == null ? 'Yopilish vaqti' : 'Yopiladi: ${_fmt(_close!)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Joylashuv', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              _location == null
                  ? "Xaritani bosib restoran joyini belgilang (kuryer shu yerga keladi)"
                  : '${_location!.latitude.toStringAsFixed(5)}, ${_location!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
            ),
            const SizedBox(height: 8),
            AppMap(
              points: [
                if (_location != null)
                  MapPoint(
                    point: _location!,
                    icon: Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
              ],
              center: _location,
              zoom: 14,
              height: 240,
              onTap: (p) => setState(() => _location = p),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Mijozlarga ochiq', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text(
                'Yopiq restoran katalogda ko\'rinmaydi',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.dark,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
