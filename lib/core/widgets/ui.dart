/// Barcha panellar uchun umumiy dizayn bo'laklari.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "assets/..." yo'li ilova ichidan, qolgani internetdan yuklanadi.
class AppImage extends StatelessWidget {
  const AppImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallbackIcon = Icons.image_outlined,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final src = url?.trim() ?? '';
    final fallback = Container(
      width: width,
      height: height,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurfaceElevated
          : AppColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: AppColors.primaryLight),
    );
    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (!src.startsWith('http')) return fallback;
    return CachedNetworkImage(
      imageUrl: src,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

/// Mayin soyali oq karta.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.radius = 18,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: color ?? (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Sarlavha yonidagi urg'u belgisi.
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(icon, size: 20, color: AppColors.warning),
                ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

/// Gorizontal tanlov chiplari. null qiymat "Barchasi" uchun.
class ChipsBar<T> extends StatelessWidget {
  const ChipsBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<(T, String)> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final (value, label) in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: value == selected
                      ? AppColors.onPrimary
                      : (isDark ? Colors.white : AppColors.dark),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Binafsha reklama bloki: sarlavha, tugma va o'ngda rasm.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.title,
    required this.buttonLabel,
    this.image,
    this.onTap,
    this.gradient = AppColors.brandGradient,
    this.height = 132,
    this.compact = false,
  });

  final String title;
  final String buttonLabel;
  final String? image;
  final VoidCallback? onTap;
  final Gradient gradient;
  final double height;

  /// Yonma-yon turadigan tor kartalar: rasm pastki o'ng burchakda.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: height,
        decoration: BoxDecoration(gradient: gradient),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (image != null)
                Positioned(
                  top: compact ? height * 0.34 : 0,
                  right: 0,
                  bottom: 0,
                  width: compact ? height * 0.8 : height * 1.05,
                  child: FadedLeftImage(image!),
                ),
              Padding(
                padding: EdgeInsets.all(compact ? 11 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        widthFactor: compact || image == null ? 1 : 0.66,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 13.5 : 16,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            shadows: const [
                              Shadow(blurRadius: 6, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PillButton(buttonLabel, small: compact),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient fonga qo'shilib ketadigan, chap cheti so'ngan rasm.
class FadedLeftImage extends StatelessWidget {
  const FadedLeftImage(this.url, {super.key, this.fadeStop = 0.45});

  final String url;
  final double fadeStop;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        colors: const [Colors.transparent, Colors.white],
        stops: [0, fadeStop],
      ).createShader(rect),
      child: AppImage(url, alignment: Alignment.topCenter),
    );
  }
}

/// Banner ichidagi oq tugmacha (bosishni ota widget bajaradi).
class PillButton extends StatelessWidget {
  const PillButton(
    this.label, {
    super.key,
    this.filled = false,
    this.small = false,
  });

  final String label;
  final bool filled;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 9 : 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: small ? 11 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: small ? 4 : 6),
          Icon(Icons.arrow_forward_rounded, size: 15, color: fg),
        ],
      ),
    );
  }
}

/// 2100 -> "2.1K"
String compactCount(int n) =>
    n < 1000 ? '$n' : '${(n / 1000).toStringAsFixed(1)}K';

class RatingLine extends StatelessWidget {
  const RatingLine(this.rating, {super.key, this.count = 0});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 17, color: AppColors.accentGold),
        const SizedBox(width: 3),
        Text(
          rating == 0 ? 'Yangi' : rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        if (count > 0)
          Text(
            ' (${compactCount(count)})',
            style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Statistik ko'rsatkich kartasi.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.hint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (hint != null)
                  Text(
                    hint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ],
      ),
    );
  }
}

/// Teng enli ustunlarga joylashadigan, balandligi o'zi moslashadigan to'r.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 160,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = ((c.maxWidth + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, 6);
        final width = (c.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Qiymatlarni solishtiruvchi sodda ustunli diagramma.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.data,
    required this.format,
    this.height = 150,
  });

  /// (o'q yozuvi, qiymat)
  final List<(String, int)> data;
  final String Function(int) format;
  final double height;

  @override
  Widget build(BuildContext context) {
    final max = data.fold<int>(0, (m, e) => e.$2 > m ? e.$2 : m);
    // Yozuvlar siqilib qolmasligi uchun har nechanchisi ko'rsatiladi.
    final every = (data.length / 8).ceil().clamp(1, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eng yuqori: ${format(max)}',
          style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < data.length; i++)
                Expanded(
                  child: Tooltip(
                    message: '${data[i].$1}: ${format(data[i].$2)}',
                    triggerMode: TooltipTriggerMode.tap,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: max == 0
                              ? 3
                              : 3 + (height - 23) * data[i].$2 / max,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == data.length - 1
                                ? AppColors.primary
                                : AppColors.primaryLight.withValues(
                                    alpha: 0.45,
                                  ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          child: (data.length - 1 - i) % every == 0
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    data[i].$1,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
