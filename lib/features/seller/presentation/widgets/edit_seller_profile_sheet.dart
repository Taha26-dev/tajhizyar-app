import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/core/widgets/form_error_box.dart';
import 'package:tajhizyar/features/seller/data/models/seller_account_model.dart';
import 'package:tajhizyar/features/seller/data/models/seller_profile_model.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_controller.dart';
import 'package:tajhizyar/features/seller/data/seller_panel_repository.dart';
import 'package:tajhizyar/features/seller/presentation/widgets/product_images_section.dart';

/// باتم‌شیت ویرایش اطلاعات فروشگاه — از پنل فروشنده باز می‌شود.
///
/// فیلدها: نام فروشگاه (اجباری)، توضیحات، شهر، تلفن، واتساپ و لوگو
/// (با انتخاب از گالری + آپلود multipart، یا وارد کردن دستی URL).
///
/// جریان کار:
///  ۱. باز شدن شیت → `GET /api/seller/profile.php` و پیش‌پر کردن فیلدها
///     (فیلدهای خالی سرور از حساب کش‌شده‌ی نشست تکمیل می‌شوند)
///  ۲. ذخیره → `PUT /api/seller/profile.php` با هر ۶ فیلد
///     (پاک کردن فیلد در فرم = ارسال رشته خالی = حذف مقدار قبلی)
///  ۳. پس از ذخیره موفق، حساب کش‌شده‌ی [SellerAuthController] هم
///     به‌روز می‌شود تا هدر پنل بی‌درنگ اطلاعات تازه را نشان دهد.
///
/// نتیجه بستن شیت: `true` یعنی ذخیره موفق بود؛ `false`/null یعنی
/// انصراف یا خطای نشست.
class EditSellerProfileSheet extends StatefulWidget {
  const EditSellerProfileSheet({
    super.key,
    required this.token,
    required this.onSessionExpired,
  });

  /// توکن نشست فروشنده (از صفحه پنل پاس داده می‌شود)
  final String token;

  /// هنگام 401 (انقضای نشست) فراخوانی می‌شود تا صفحه پنل
  /// کاربر را به صفحه ورود هدایت کند.
  final VoidCallback onSessionExpired;

  /// نمایش شیت و برگرداندن نتیجه ذخیره.
  static Future<bool?> show(
    BuildContext context, {
    required String token,
    required VoidCallback onSessionExpired,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => EditSellerProfileSheet(
        token: token,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  @override
  State<EditSellerProfileSheet> createState() =>
      _EditSellerProfileSheetState();
}

class _EditSellerProfileSheetState extends State<EditSellerProfileSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();

  SellerPanelRepository? _repository;

  SellerPanelRepository get _repositoryLazy =>
      _repository ??= SellerPanelRepository();

  // ── دریافت اطلاعات فعلی ──
  bool _isLoadingProfile = true;
  String? _profileError;

  // ── ارسال ──
  bool _isSubmitting = false;
  String? _errorMessage;

  // ── لوگو (انتخاب/آپلود/پاک کردن) ──
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingLogo = false;
  String? _logoNotice;

  /// فایل محلی انتخاب‌شده برای پیش‌نمایش در حین آپلود
  XFile? _pickedLogoFile;

  @override
  void initState() {
    super.initState();
    // تغییر URL لوگو → به‌روزرسانی پیش‌نمایش و دکمه «حذف لوگو»
    _logoUrlController.addListener(_onLogoUrlChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _logoUrlController.removeListener(_onLogoUrlChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _logoUrlController.dispose();
    _repository?.dispose();
    super.dispose();
  }

  // ─────────── دریافت اطلاعات فعلی ───────────

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final SellerProfileModel profile =
          await _repositoryLazy.fetchProfile(widget.token);
      if (!mounted) return;
      _prefill(profile);
      setState(() => _isLoadingProfile = false);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isSessionExpired) {
        _closeAndExpireSession();
        return;
      }
      setState(() {
        _isLoadingProfile = false;
        _profileError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'دریافت اطلاعات فروشگاه انجام نشد؛ دوباره تلاش کنید.';
      });
    }
  }

  /// پر کردن فیلدها از پاسخ سرور — فیلدهای خالی سرور (مثلاً فروشنده‌ای
  /// که هنوز تلفن ثبت نکرده) از حساب کش‌شده‌ی نشست تکمیل می‌شوند.
  void _prefill(SellerProfileModel profile) {
    final SellerAccountModel? account = SellerAuthController.instance.account;

    String pick(String fromProfile, String? fromAccount) =>
        fromProfile.isNotEmpty ? fromProfile : (fromAccount ?? '');

    // نام جای‌نگهدار «فروشنده» به‌عنوان نام واقعی پیش‌پر نمی‌شود.
    final String? accountName = account?.name;
    final String accountRealName =
        (accountName == null || accountName == 'فروشنده') ? '' : accountName;

    _nameController.text = pick(profile.name, accountRealName);
    _descriptionController.text = profile.description ?? '';
    _cityController.text = pick(profile.city ?? '', account?.city);
    _phoneController.text = pick(profile.phone ?? '', account?.phone);
    _whatsappController.text = pick(profile.whatsapp ?? '', account?.whatsapp);
    _logoUrlController.text = pick(profile.logoUrl ?? '', account?.logoUrl);
  }

  // ─────────── لوگو: انتخاب و آپلود ───────────

  void _onLogoUrlChanged() {
    if (mounted) setState(() {});
  }

  /// انتخاب لوگو از گالری → اعتبارسنجی فرمت/حجم → آپلود → قرار دادن URL.
  Future<void> _pickLogo() async {
    if (_isSubmitting || _isUploadingLogo) return;

    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted || picked == null) return;

    final String extension = picked.name.split('.').last.trim().toLowerCase();
    if (!kAllowedImageExtensions.contains(extension)) {
      setState(() {
        _logoNotice = 'فرمت «${picked.name}» پشتیبانی نمی‌شود؛ '
            'فقط JPG، PNG و WebP مجاز است.';
      });
      return;
    }

    try {
      final int size = await picked.length();
      if (size > kMaxImageBytes) {
        setState(() {
          _logoNotice = 'حجم تصویر بیش از ۳۰۰ کیلوبایت است؛ '
              'تصویر کوچک‌تری انتخاب کنید.';
        });
        return;
      }
    } catch (_) {
      setState(() {
        _logoNotice = 'خواندن فایل ممکن نشد؛ تصویر را دوباره انتخاب کنید.';
      });
      return;
    }

    setState(() {
      _isUploadingLogo = true;
      _logoNotice = null;
      _pickedLogoFile = picked;
    });

    try {
      final String url = await _repositoryLazy.uploadProductImage(
        widget.token,
        filePath: picked.path,
        fileName: picked.name,
        mimeType: picked.mimeType,
      );
      if (!mounted) return;
      setState(() {
        _isUploadingLogo = false;
        _pickedLogoFile = null;
        _logoUrlController.text = url;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isSessionExpired) {
        _closeAndExpireSession();
        return;
      }
      setState(() {
        _isUploadingLogo = false;
        _pickedLogoFile = null;
        _logoNotice = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploadingLogo = false;
        _pickedLogoFile = null;
        _logoNotice = 'آپلود لوگو انجام نشد؛ اتصال اینترنت را بررسی کنید.';
      });
    }
  }

  // ─────────── ذخیره ───────────

  Future<void> _submit() async {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isUploadingLogo) {
      setState(() => _errorMessage = 'لطفاً تا پایان آپلود لوگو صبر کنید.');
      return;
    }

    setState(() => _isSubmitting = true);

    final String name = _nameController.text.trim();
    final String description = _descriptionController.text.trim();
    final String city = _cityController.text.trim();
    final String phone = _normalizedPhone(_phoneController.text);
    final String whatsapp = _normalizedPhone(_whatsappController.text);
    final String logoUrl = _logoUrlController.text.trim();

    try {
      await _repositoryLazy.updateProfile(
        widget.token,
        name: name,
        description: description,
        phone: phone,
        whatsapp: whatsapp,
        city: city,
        logoUrl: logoUrl,
      );

      // به‌روزرسانی حساب کش‌شده (حافظه + حافظه دائمی) — فیلدهای
      // غیرقابل ویرایش (id، username، isVerified) حفظ می‌شوند.
      final SellerAccountModel current =
          SellerAuthController.instance.account ??
              SellerAccountModel(id: 0, name: name);
      if (!mounted) return;
      await SellerAuthController.instance.updateAccount(
        SellerAccountModel(
          id: current.id,
          name: name,
          username: current.username,
          logoUrl: ApiConstants.resolveUrl(logoUrl),
          city: city.isEmpty ? null : city,
          phone: phone.isEmpty ? null : phone,
          whatsapp: whatsapp.isEmpty ? null : whatsapp,
          isVerified: current.isVerified,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true); // موفق → پنل هدر را refresh می‌کند
    } on ApiException catch (error) {
      if (!mounted) return;
      // انقضای نشست → بستن شیت و هدایت به صفحه ورود
      if (error.isSessionExpired) {
        Navigator.of(context).pop(false);
        widget.onSessionExpired();
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'ذخیره اطلاعات فروشگاه انجام نشد؛ '
            'لطفاً دوباره تلاش کنید.';
      });
    }
  }

  /// انقضای نشست (دریافت پروفایل یا آپلود لوگو) — بستن شیت و هدایت به ورود
  void _closeAndExpireSession() {
    if (!mounted) return;
    Navigator.of(context).pop(false);
    widget.onSessionExpired();
  }

  /// نرمال‌سازی شماره تلفن: ارقام فارسی/عربی → لاتین + حذف فاصله/خط تیره
  String _normalizedPhone(String raw) =>
      normalizeDigits(raw).replaceAll(RegExp(r'[\s\-()]'), '');

  // ─────────── اعتبارسنجی ───────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'نام فروشگاه را وارد کنید.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    return _validateOptionalPhone(value, 'شماره تلفن');
  }

  String? _validateWhatsapp(String? value) {
    return _validateOptionalPhone(value, 'شماره واتساپ');
  }

  String? _validateOptionalPhone(String? value, String label) {
    final String digits = normalizeDigits(value ?? '')
        .replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return null; // اختیاری
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(digits)) {
      return '$label معتبر نیست (مثلاً ۰۹۱۲۳۴۵۶۷۸۹).';
    }
    return null;
  }

  String? _validateLogoUrl(String? value) {
    final String url = (value ?? '').trim();
    if (url.isEmpty) return null; // اختیاری
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('/')) {
      return 'آدرس لوگو باید با http، https یا / شروع شود.';
    }
    return null;
  }

  // ─────────── UI ───────────

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // ── حالت دریافت اطلاعات ──
    if (_isLoadingProfile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildSheetHeader(context),
            const SizedBox(height: 36),
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'در حال دریافت اطلاعات فروشگاه…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    // ── حالت خطای دریافت (با تلاش مجدد) ──
    if (_profileError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSheetHeader(context),
            const SizedBox(height: 16),
            FormErrorBox(message: _profileError!),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('بستن'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadProfile,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('تلاش مجدد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── فرم ──
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSheetHeader(context),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...<Widget>[
              FormErrorBox(message: _errorMessage!),
              const SizedBox(height: 16),
            ],

            // ── لوگو ──
            _buildLogoSection(),
            const SizedBox(height: 16),

            // ── نام فروشگاه ──
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              enabled: !_isSubmitting,
              maxLength: 80,
              buildCounter: (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) =>
                  null, // شمارنده پیش‌فرض مخفی
              decoration: const InputDecoration(
                labelText: 'نام فروشگاه *',
                hintText: 'مثلاً: ابزارآلات صنعتی پارس',
                prefixIcon: Icon(Icons.storefront_rounded),
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 16),

            // ── شهر ──
            TextFormField(
              controller: _cityController,
              textInputAction: TextInputAction.next,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'شهر',
                hintText: 'مثلاً: تهران',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ── تلفن ──
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'شماره تلفن',
                hintText: 'مثلاً: 09123456789',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: 16),

            // ── واتساپ ──
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'شماره واتساپ',
                hintText: 'با کد کشور یا بدون آن',
                prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
              ),
              validator: _validateWhatsapp,
            ),
            const SizedBox(height: 16),

            // ── توضیحات ──
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'توضیحات فروشگاه',
                hintText: 'معرفی کوتاه محصولات و خدمات…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // ── دکمه‌های انصراف / ذخیره ──
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('انصراف'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ذخیره تغییرات'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// هدر شیت: دستگیره + عنوان + دکمه بستن
  Widget _buildSheetHeader(BuildContext context) {
    return Column(
      children: <Widget>[
        // دستگیره کشیدن (drag handle)
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            const Icon(
              Icons.storefront_rounded,
              color: AppColors.secondary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ویرایش اطلاعات فروشگاه',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textSecondary,
              tooltip: 'بستن',
            ),
          ],
        ),
      ],
    );
  }

  /// بخش لوگو: پیش‌نمایش + فیلد URL + دکمه انتخاب از گالری / حذف
  Widget _buildLogoSection() {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _buildLogoPreview(),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _logoUrlController,
                enabled: !_isSubmitting && !_isUploadingLogo,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'آدرس لوگو (URL)',
                  hintText: 'مثلاً: /uploads/logo.webp',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                validator: _validateLogoUrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            OutlinedButton.icon(
              onPressed:
                  (_isSubmitting || _isUploadingLogo) ? null : _pickLogo,
              icon: _isUploadingLogo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(_isUploadingLogo ? 'در حال آپلود…' : 'انتخاب از گالری'),
            ),
            if (_logoUrlController.text.trim().isNotEmpty &&
                !_isUploadingLogo) ...<Widget>[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _logoUrlController.clear(),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('حذف لوگو'),
              ),
            ],
          ],
        ),
        if (_logoNotice != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
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
                    _logoNotice!,
                    style: textTheme.labelSmall?.copyWith(
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

  /// پیش‌نمایش دایره‌ای لوگو — فایل محلی در حین آپلود، URL ذخیره‌شده،
  /// یا آیکون پیش‌فرض فروشگاه.
  Widget _buildLogoPreview() {
    final XFile? picked = _pickedLogoFile;
    final String? resolvedUrl =
        picked == null ? ApiConstants.resolveUrl(_logoUrlController.text) : null;

    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (picked != null)
            Image.file(
              File(picked.path),
              fit: BoxFit.cover,
            )
          else if (resolvedUrl != null)
            Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, Object? __, StackTrace? ___) => const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            )
          else
            const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          if (_isUploadingLogo)
            Container(
              color: Colors.black38,
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
        ],
      ),
    );
  }
}
