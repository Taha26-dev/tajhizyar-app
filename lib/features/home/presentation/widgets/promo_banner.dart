import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/theme/app_theme.dart';

/// بنر تبلیغاتی استاتیک «پیشنهاد ویژه این هفته».
///
/// TODO: در آینده داده‌های این بنر از API بنرها دریافت خواهد شد.
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, required this.onTap});

  /// رویداد کلیک روی بنر / دکمه «مشاهده پیشنهادها»
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: <Color>[AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        // در RTL «start» یعنی سمت راست
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.local_offer_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'پیشنهاد ویژه این هفته',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'تخفیف‌های ویژه روی برندهای معتبر ابزار و تجهیزات صنعتی',
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xCCFFFFFF),
              fontSize: 12.5,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                child: const Text('مشاهده پیشنهادها'),
              ),
              const Spacer(),
              const Icon(
                Icons.precision_manufacturing_rounded,
                size: 52,
                color: Color(0x26FFFFFF),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
