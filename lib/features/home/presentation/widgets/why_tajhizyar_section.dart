import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/features/home/presentation/widgets/section_header.dart';

/// بخش «چرا تجهیزیار؟» — سه مزیت کلیدی پلتفرم در یک کارت ساده.
///
/// طراحی کم‌حجم و غیرشلوغ: سه ستون با آیکون دایره‌ای رنگی و عنوان
/// کوتاه، با جداکننده‌های ظریف عمودی. رنگ‌ها از پالت سراسری
/// [AppColors] خوانده می‌شوند.
class WhyTajhizyarSection extends StatelessWidget {
  const WhyTajhizyarSection({super.key});

  @override
  Widget build(BuildContext context) {
    // کل درخت const است — هم بهینه، هم بدون لینت اضافه
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── سرتیتر بخش (هم‌سبک بقیه بخش‌های صفحه اصلی) ──
          SectionHeader(title: 'چرا تجهیزیار؟'),
          SizedBox(height: 10),

          // ── کارت مزیت‌ها ──
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _WhyItem(
                      icon: Icons.verified_rounded,
                      color: AppColors.success,
                      label: 'فروشندگان تأییدشده',
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _WhyItem(
                      icon: Icons.price_check_rounded,
                      color: AppColors.secondary,
                      label: 'قیمت شفاف و به‌روز',
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _WhyItem(
                      icon: Icons.support_agent_rounded,
                      color: AppColors.primary,
                      label: 'ارتباط مستقیم با فروشنده',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// یک آیتم مزیت — آیکون دایره‌ای روی تینت کم‌رنگ + عنوان کوتاه.
class _WhyItem extends StatelessWidget {
  const _WhyItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;

  /// رنگ آیکون (از [AppColors]) — تینت پس‌زمینه از همین رنگ ساخته می‌شود
  final Color color;

  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// جداکننده عمودی ظریف بین آیتم‌ها.
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: AppColors.border.withValues(alpha: 0.7),
    );
  }
}
