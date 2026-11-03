import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/features/seller/data/seller_panel_repository.dart';

/// حداکثر تعداد عکس مجاز برای هر محصول
const int kMaxProductImages = 3;

/// حداکثر حجم هر تصویر در سمت کلاینت (~۳۰۰ کیلوبایت) —
/// تبدیل نهایی به WebP سمت سرور انجام می‌شود.
/// (قاعده مشترک تصاویر محصول و لوگوی فروشگاه)
const int kMaxImageBytes = 300 * 1024;

/// فرمت‌های مجاز تصویر
const List<String> kAllowedImageExtensions = <String>['jpg', 'jpeg', 'png', 'webp'];

/// وضعیت یک تصویر در فرم — از انتخاب تا پایان آپلود.
class _ImageEntry {
  _ImageEntry({this.localFile, this.remoteUrl});

  /// فایل محلی برای پیش‌نمایش (عکس‌های تازه‌انتخاب‌شده)
  final XFile? localFile;

  /// آدرس سرور پس از آپلود موفق (عکس‌های ذخیره‌شده در ویرایش هم این را دارند)
  String? remoteUrl;

  bool isUploading = false;
  bool hasError = false;
  String? errorMessage;

  /// آیا تصویر آماده ارسال همراه محصول است؟
  bool get isReady => remoteUrl != null && !hasError;
}

/// بخش مدیریت تصاویر محصول در فرم افزودن/ویرایش پنل فروشنده.
///
/// - انتخاب از گالری (چندتایی) با پیش‌نمایش افقی قابل اسکرول
/// - حداکثر [kMaxProductImages] عکس؛ بررسی فرمت (JPG/PNG/WebP) و
///   حجم (~۳۰۰KB) پیش از آپلود
/// - آپلود هر عکس به‌صورت multipart به `POST /api/seller/upload.php`
///   با نوار وضعیت مستقل (در حال آپلود / خطا با تلاش مجدد / آماده)
/// - حذف هر عکس پیش از ثبت نهایی محصول
///
/// فراخوان با [onChanged] فهرست URLهای آماده را بی‌درنگ به فرم والد
/// می‌دهد و [onUploadBusyChanged] وضعیت «آپلود در جریان» را اعلام
/// می‌کند تا دکمه ذخیره تا پایان آپلودها قفل بماند.
class ProductImagesSection extends StatefulWidget {
  const ProductImagesSection({
    super.key,
    required this.token,
    required this.repository,
    required this.onChanged,
    required this.onUploadBusyChanged,
    this.initialImageUrls = const <String>[],
    this.enabled = true,
    this.onSessionExpired,
  });

  /// توکن نشست فروشنده
  final String token;

  /// ریپازیتوری مشترک پنل (از فرم والد — والد dispose می‌کند)
  final SellerPanelRepository repository;

  /// تصاویر فعلی محصول در حالت ویرایش (آدرس مطلق)
  final List<String> initialImageUrls;

  /// فرم فعال است؟ (در زمان ثبت نهایی غیرفعال می‌شود)
  final bool enabled;

  /// هر تغییر در فهرست URLهای آماده ارسال
  final ValueChanged<List<String>> onChanged;

  /// شروع/پایان آپلود حداقل یک تصویر
  final ValueChanged<bool> onUploadBusyChanged;

  /// هنگام 401 (انقضای نشست در حین آپلود)
  final VoidCallback? onSessionExpired;

  @override
  State<ProductImagesSection> createState() => _ProductImagesSectionState();
}

class _ProductImagesSectionState extends State<ProductImagesSection> {
  final ImagePicker _picker = ImagePicker();
  final List<_ImageEntry> _entries = <_ImageEntry>[];

  /// پیام راهنما/خطای انتخاب و اعتبارسنجی (زیر ردیف عکس‌ها)
  String? _notice;

  @override
  void initState() {
    super.initState();
    // تصاویر فعلی محصول (حالت ویرایش) — فقط تا سقف مجاز
    for (final String url in widget.initialImageUrls) {
      if (_entries.length >= kMaxProductImages) break;
      if (url.trim().isNotEmpty) {
        _entries.add(_ImageEntry(remoteUrl: url));
      }
    }
  }

  // ─────────── انتخاب و اعتبارسنجی ───────────

  Future<void> _pickAndUpload() async {
    if (!widget.enabled) return;

    final int remaining = kMaxProductImages - _entries.length;
    if (remaining <= 0) {
      _setNotice(
        'حداکثر ${toPersianDigits('$kMaxProductImages')} عکس مجاز است؛ '
        'برای تغییر، ابتدا یکی را حذف کنید.',
      );
      return;
    }

    final List<XFile> picked = await _picker.pickMultiImage();
    if (!mounted || picked.isEmpty) return;

    String? notice;
    final List<XFile> selected = <XFile>[];
    for (final XFile file in picked) {
      if (selected.length >= remaining) {
        notice = 'حداکثر ${toPersianDigits('$kMaxProductImages')} عکس مجاز است؛ '
            'فقط ${toPersianDigits('$remaining')} عکس اول اضافه شد.';
        break;
      }
      final String fileExtension =
          file.name.split('.').last.trim().toLowerCase();
      if (!kAllowedImageExtensions.contains(fileExtension)) {
        notice = 'فرمت «${file.name}» پشتیبانی نمی‌شود؛ '
            'فقط JPG، PNG و WebP مجاز است.';
        continue;
      }
      try {
        final int size = await file.length();
        if (size > kMaxImageBytes) {
          notice = 'حجم «${file.name}» بیش از ۳۰۰ کیلوبایت است؛ '
              'عکس کوچک‌تری انتخاب کنید.';
          continue;
        }
      } catch (_) {
        notice = 'خواندن «${file.name}» ممکن نشد؛ فایل را دوباره انتخاب کنید.';
        continue;
      }
      selected.add(file);
    }

    if (!mounted) return;
    if (selected.isEmpty) {
      _setNotice(notice ?? 'عکسی برای افزودن انتخاب نشد.');
      return;
    }

    // همه عکس‌های معتبر بلافاصله با وضعیت «در حال آپلود» اضافه می‌شوند
    // و آپلودشان به‌صورت موازی انجام می‌شود.
    final List<_ImageEntry> fresh = <_ImageEntry>[
      for (final XFile file in selected)
        _ImageEntry(localFile: file)..isUploading = true,
    ];
    setState(() {
      _notice = notice;
      _entries.addAll(fresh);
    });
    _notify();

    await Future.wait(<Future<void>>[
      for (final _ImageEntry entry in fresh) _uploadEntry(entry),
    ]);
  }

  // ─────────── آپلود / حذف ───────────

  /// آپلود یک تصویر — نتیجه (موفق/خطا) روی خود entry نوشته می‌شود؛
  /// خطا پرتاب نمی‌شود (مناسب `Future.wait` موازی).
  Future<void> _uploadEntry(_ImageEntry entry) async {
    final XFile? file = entry.localFile;
    if (file == null) return;

    try {
      final String url = await widget.repository.uploadProductImage(
        widget.token,
        filePath: file.path,
        fileName: file.name,
        mimeType: file.mimeType,
      );
      entry
        ..remoteUrl = url
        ..isUploading = false
        ..hasError = false
        ..errorMessage = null;
    } on ApiException catch (error) {
      entry
        ..isUploading = false
        ..hasError = true
        ..errorMessage = error.message;
      if (error.isSessionExpired) {
        // انقضای نشست در حین آپلود — صفحه پنل به ورود هدایت می‌شود
        widget.onSessionExpired?.call();
        return;
      }
    } catch (_) {
      entry
        ..isUploading = false
        ..hasError = true
        ..errorMessage = 'آپلود تصویر انجام نشد؛ اتصال اینترنت را بررسی کنید.';
    }

    if (!mounted) return;
    _notify(
      notice: entry.hasError
          ? 'آپلود «${file.name}» ناموفق بود: ${entry.errorMessage} '
              'برای تلاش مجدد روی تصویر بزنید.'
          : null,
    );
  }

  void _remove(_ImageEntry entry) {
    if (!widget.enabled) return;
    setState(() {
      _entries.remove(entry);
      _notice = null;
    });
    _notifySilently();
  }

  // ─────────── اطلاع‌رسانی به فرم والد ───────────

  void _setNotice(String notice) {
    setState(() => _notice = notice);
  }

  /// به‌روزرسانی UI + اعلام وضعیت به فرم والد
  void _notify({String? notice}) {
    setState(() {
      if (notice != null) _notice = notice;
    });
    _notifySilently();
  }

  /// اعلام وضعیت به فرم والد بدون setState (برای مسیرهای پس از await)
  void _notifySilently() {
    widget.onUploadBusyChanged(
      _entries.any((_ImageEntry entry) => entry.isUploading),
    );
    widget.onChanged(_uploadedUrls());
  }

  /// URLهای آماده ارسال (فقط آپلودشده‌های موفق) — به ترتیب نمایش
  List<String> _uploadedUrls() => <String>[
        for (final _ImageEntry entry in _entries)
          if (entry.isReady) entry.remoteUrl!,
      ];

  // ─────────── UI ───────────

  @override
  Widget build(BuildContext context) {
    final bool canAdd = widget.enabled && _entries.length < kMaxProductImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.photo_library_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'تصاویر محصول',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Text(
              '${toPersianDigits('${_entries.length}')} از '
              '${toPersianDigits('$kMaxProductImages')}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // پیش‌نمایش افقی قابل اسکرول (در RTL راست‌به‌چپ)
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _entries.length + (canAdd ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index == _entries.length) {
                return _buildAddTile(context);
              }
              return _buildImageTile(context, _entries[index]);
            },
          ),
        ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _notice!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// کاشی «افزودن عکس» — باز کردن گالری
  Widget _buildAddTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.enabled ? _pickAndUpload : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'افزودن عکس',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// کاشی پیش‌نمایش یک تصویر — با وضعیت آپلود/خطا و دکمه حذف
  Widget _buildImageTile(BuildContext context, _ImageEntry entry) {
    final Widget preview = entry.localFile != null
        ? Image.file(
            File(entry.localFile!.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        : Image.network(
            entry.remoteUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, Object? __, StackTrace? ___) => Container(
              color: AppColors.background,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                size: 26,
                color: AppColors.textSecondary,
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          children: <Widget>[
            // تصویر + حاشیه وضعیت (خطا = قرمز) — لمس در حالت خطا = تلاش مجدد
            GestureDetector(
              onTap:
                  (widget.enabled && entry.hasError) ? () => _uploadEntry(entry) : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: entry.hasError ? AppColors.error : AppColors.border,
                    width: entry.hasError ? 1.6 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.5),
                  child: preview,
                ),
              ),
            ),

            // پوشش «در حال آپلود»
            if (entry.isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // پوشش خطا — آیکون تلاش مجدد
            if (entry.hasError)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),

            // دکمه حذف — گوشه بالا-ابتدا
            PositionedDirectional(
              top: 4,
              end: 4,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.enabled ? () => _remove(entry) : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.transparent,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
