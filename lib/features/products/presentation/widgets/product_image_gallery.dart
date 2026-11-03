import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';

/// گالری تصاویر محصول — PageView افقی قابل سوایپ با نشانگر نقطه‌ای (dots)
/// زیر تصاویر.
///
/// ارتفاع گالری «کاملاً کنترل‌شده» است: کادر گالری یک [Container] با
/// اندازه صریح (width × height) است که ارتفاعش از نسبت ۴:۳ عرض موجود
/// محاسبه و در بازه امن [_minGalleryHeight، _maxGalleryHeight] clamp
/// می‌شود — بنابراین در هیچ حالتی (موبایل، تبلت، صفحه باریک، تصویر با
/// هر نسبت ابعادی) تصویر از کادر بیرون نمی‌زند و حالت تمام‌صفحه نمی‌گیرد.
///
/// تصویر با `BoxFit.cover` داخل کادر پر می‌شود (اضافه‌ی ابعادی تصویر
/// crop می‌شود، نه اینکه بیرون بزند) و `clipBehavior: Clip.antiAlias`
/// کانتینر به‌عنوان لایه محافظ، هر paint خارج از کادر را هم کیپ می‌کند.
///
/// اگر فهرست تصاویر خالی باشد، یک placeholder مناسب نمایش داده می‌شود و
/// نشانگرها فقط زمانی ظاهر می‌شوند که بیش از یک تصویر وجود داشته باشد.
class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({super.key, required this.imageUrls});

  /// آدرس‌های کامل تصاویر محصول (ممکن است خالی باشد)
  final List<String> imageUrls;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  /// کف و سقف ارتفاع کادر گالری (منطقی) — ارتفاع هرگز از این بازه
  /// خارج نمی‌شود تا گالری نه خیلی کوتاه و نه تمام‌صفحه شود.
  static const double _minGalleryHeight = 200;
  static const double _maxGalleryHeight = 340;

  /// نسبت ابعاد کادر — ۴:۳ (عرض به ارتفاع)
  static const double _aspectRatio = 4 / 3;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPage = index);

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.imageUrls;
    final bool hasImages = images.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ── کادر مشخص گالری: ارتفاع صریح، محدود و کنترل‌شده ──
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width =
                constraints.maxWidth.isFinite && constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : 400; // fallback ایمن برای عرض نامحدود

            // نسبت ۴:۳ روی عرض موجود، اما همیشه clamp‌شده در بازه امن
            final double height = (width / _aspectRatio)
                .clamp(_minGalleryHeight, _maxGalleryHeight);

            return Container(
              width: width,
              height: height, // ← ارتفاع ثابت؛ گالری هرگز رشد نمی‌کند
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.border),
                ),
              ),
              // لایه محافظ: هر محتوایی خارج از کادر باشد کیپ می‌شود
              clipBehavior: Clip.antiAlias,
              child: hasImages
                  ? PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (BuildContext context, int index) =>
                          _GalleryImage(url: images[index]),
                    )
                  : const _GalleryPlaceholder(),
            );
          },
        ),
        // ── نشانگر صفحات (dots) ──
        if (hasImages && images.length > 1) ...<Widget>[
          const SizedBox(height: 10),
          _PageDots(count: images.length, currentPage: _currentPage),
        ],
      ],
    );
  }
}

/// یک صفحه از گالری — تصویر شبکه‌ای با placeholder در حالت لودینگ/خطا.
class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    // cover → تصویر کادر را کامل پر می‌کند ولی هرگز بیرون نمی‌زند
    // (اضافه‌ی ابعادی crop می‌شود)؛ contain → تصویر کوچک‌تر از کادر
    // با حاشیه دیده می‌شد. cover + کیپ کانتینر = بدون overflow.
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      loadingBuilder:
          (BuildContext context, Widget child, ImageChunkEvent? progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.background,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: AppColors.primary),
        );
      },
      errorBuilder: (_, Object __, StackTrace? ___) =>
          const _GalleryPlaceholder(),
    );
  }
}

/// placeholder نبود/خطای تصویر.
class _GalleryPlaceholder extends StatelessWidget {
  const _GalleryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primarySoft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.image_outlined, size: 56, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text(
            'تصویری برای این محصول ثبت نشده است',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// نشانگر نقطه‌ای صفحات — نقطه فعال پهن‌تر و سرمه‌ای است.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.currentPage});

  final int count;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
