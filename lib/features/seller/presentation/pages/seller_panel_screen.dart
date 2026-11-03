import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/constants/error_messages.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/core/widgets/accent_section_title.dart';
import 'package:tajhizyar/core/widgets/empty_view.dart';
import 'package:tajhizyar/core/widgets/error_view.dart';
import 'package:tajhizyar/core/widgets/loading_view.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';
import 'package:tajhizyar/features/seller/data/models/seller_account_model.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_controller.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_repository.dart';
import 'package:tajhizyar/features/seller/data/seller_panel_repository.dart';
import 'package:tajhizyar/features/seller/presentation/utils/session_utils.dart';
import 'package:tajhizyar/features/seller/presentation/widgets/edit_seller_profile_sheet.dart';
import 'package:tajhizyar/features/seller/presentation/widgets/panel_product_card.dart';
import 'package:tajhizyar/features/seller/presentation/widgets/product_form_sheet.dart';

/// پنل مدیریت فروشنده — مسیر `/seller/panel` (فقط برای فروشنده لاگین‌شده).
///
/// بخش‌ها:
///  ۱. AppBar «پنل فروشنده» + دکمه خروج از دستگاه فعلی
///     (`POST /api/seller/logout.php`)
///  ۲. هدر حساب: لوگو/آواتار، نام فروشگاه، نام کاربری، شهر، نشان تأییدشده
///     + دکمه «ویرایش اطلاعات فروشگاه» ([EditSellerProfileSheet])
///  ۳. «محصولات من»: لیست با ویرایش و حذف (کارت مدیریت [PanelProductCard])
///  ۴. کارت «خروج از همه دستگاه‌ها»
///     (`POST /api/seller/logout-all.php`)
///  ۵. دکمه شناور «افزودن محصول جدید» → فرم [ProductFormSheet]
///
/// خروج (هر دو نوع): ابتدا پایان نشست در سرور فراخوانی می‌شود و سپس
/// «در هر حالتی» توکن محلی پاک و کاربر به صفحه ورود هدایت می‌شود.
///
/// گارد نشست: روتر بدون توکن را به `/seller/login` هدایت می‌کند؛
/// علاوه بر آن، خطای 401 از سرور (توکن باطل یا منقضی — شامل ابطال با
/// «خروج از همه دستگاه‌ها» در دستگاه دیگر) هم باعث پاک شدن نشست
/// و هدایت مجدد به صفحه ورود می‌شود.
class SellerPanelScreen extends StatefulWidget {
  const SellerPanelScreen({super.key});

  @override
  State<SellerPanelScreen> createState() => _SellerPanelScreenState();
}

class _SellerPanelScreenState extends State<SellerPanelScreen> {
  SellerPanelRepository? _repository;
  SellerAuthRepository? _authRepository;

  String? _token;
  SellerAccountModel? _account;

  bool _initializing = true; // خواندن نشست از حافظه محلی
  bool _loading = false; // در حال دریافت محصولات
  bool _loggingOut = false; // در حال پایان دادن به نشست در سرور (خروج)
  String? _error; // پیام خطای دریافت محصولات (null = پیام پیش‌فرض)
  List<ProductModel> _products = const <ProductModel>[];

  /// شناسه محصولی که عملیات حذف آن در جریان است (اسپینر روی همان کارت)
  int? _deletingProductId;

  SellerPanelRepository get _repositoryLazy =>
      _repository ??= SellerPanelRepository();

  /// ساخت تنبل ریپازیتوری احراز هویت — فقط برای فراخوانی خروج
  SellerAuthRepository get _authRepositoryLazy =>
      _authRepository ??= SellerAuthRepository();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _repository?.dispose();
    _authRepository?.dispose();
    super.dispose();
  }

  // ─────────── چرخه نشست و داده ───────────

  /// خواندن نشست از کنترلر (کش حافظه) و سپس دریافت محصولات.
  Future<void> _bootstrap() async {
    // یک فریم صبر تا ناوبری احتمالی خارج از فاز build انجام شود.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    // لایه محافظ اضافی — ردایرکت روتر باید قبلاً جلوی این را گرفته باشد.
    final String? token = SellerAuthController.instance.token;
    if (token == null) {
      context.go(AppRoutes.sellerLogin);
      return;
    }

    _token = token;
    _account = SellerAuthController.instance.account;
    setState(() => _initializing = false);
    await _loadProducts();
  }

  /// دریافت (یا به‌روزرسانی) فهرست محصولات خودم.
  Future<void> _loadProducts() async {
    final String? token = _token;
    if (token == null || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<ProductModel> products =
          await _repositoryLazy.fetchMyProducts(token);
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      // انقضای نشست (۴۰۱) → خروج اجباری + هدایت به صفحه ورود
      if (error.isSessionExpired) {
        await _forceRelogin();
        return;
      }
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMessages.unknown;
      });
    }
  }

  /// پاک کردن نشست و هدایت به صفحه ورود (خروج اجباری با انقضای توکن) —
  /// پیاده‌سازی مشترک در [forceRelogin] تا همه‌جا رفتار یکسان باشد.
  Future<void> _forceRelogin() => forceRelogin(context);

  /// خروج از حساب — دستگاه فعلی یا همه دستگاه‌ها.
  ///
  /// ترتیب عملیات:
  ///  ۱. تأیید کاربر با دیالوگ
  ///  ۲. فراخوانی سرور: `logout.php` (دستگاه فعلی) یا
  ///     `logout-all.php` (همه دستگاه‌ها) با توکن Bearer
  ///  ۳. پاک کردن کامل نشست محلی و هدایت به صفحه ورود — «در هر حالتی»
  ///     حتی اگر فراخوانی سرور ناموفق بود (مثلاً قطع اینترنت)، خروج
  ///     محلی انجام می‌شود و فقط پیام هشدار مناسب نمایش داده می‌شود.
  Future<void> _logout({required bool allDevices}) async {
    if (_loggingOut) return;

    final bool? confirmed = await _showConfirmDialog(
      title: allDevices ? 'خروج از همه دستگاه‌ها' : 'خروج از حساب',
      message: allDevices
          ? 'با این کار نشست شما در همه دستگاه‌ها — از جمله همین دستگاه — '
              'پایان داده می‌شود و باید دوباره وارد شوید.\n\n'
              'آیا مطمئن هستید؟'
          : 'آیا مطمئن هستید که می‌خواهید از حساب خود خارج شوید؟',
      confirmLabel: allDevices ? 'خروج از همه' : 'خروج',
      isDestructive: allDevices,
    );
    if (confirmed != true) return;
    if (!mounted) return; // دیالوگ ممکن است بعد از dispose بودن صفحه بسته شود

    final String? token = _token;
    if (token == null) return;

    // گرفتن messenger قبل از await (الگوی امن کل پروژه)
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _loggingOut = true);

    // پیام هشدار در صورت ناموفق بودن پایان نشست سمت سرور — null یعنی موفق
    String? warningNotice;
    try {
      if (allDevices) {
        await _authRepositoryLazy.logoutAll(token: token);
      } else {
        await _authRepositoryLazy.logout(token: token);
      }
    } on ApiException catch (error) {
      // ۴۰۱ یعنی نشست از قبل در سرور باطل است — خروج محلی کافی است.
      if (!error.isSessionExpired) {
        warningNotice = _logoutWarning(allDevices);
      }
    } catch (_) {
      warningNotice = _logoutWarning(allDevices);
    }

    // پاک کردن توکن و نشست محلی — بدون وابستگی به نتیجه فراخوانی سرور
    await SellerAuthController.instance.signOut();
    if (!mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            warningNotice ??
                (allDevices
                    ? 'از همه دستگاه‌ها خارج شدید.'
                    : 'از حساب خود خارج شدید.'),
          ),
        ),
      );
    context.go(AppRoutes.sellerLogin);
  }

  /// پیام هشدار خروج — وقتی فراخوانی سرور ناموفق بود ولی خروج محلی
  /// انجام می‌شود (توکن محلی پاک شده، اما ابطال سمت سرور تضمین نیست).
  static String _logoutWarning(bool allDevices) => allDevices
      ? 'از این دستگاه خارج شدید؛ اما خروج از سایر دستگاه‌ها ممکن نشد؛ '
          'اتصال اینترنت را بررسی کنید.'
      : 'از حساب خارج شدید؛ اما پایان نشست در سرور انجام نشد.';

  /// ویرایش اطلاعات فروشگاه (نام، توضیحات، شهر، تلفن، واتساپ، لوگو) —
  /// پس از ذخیره موفق، هدر پنل از حساب به‌روزشده‌ی کنترلر تازه می‌شود.
  Future<void> _editProfile() async {
    final String? token = _token;
    if (token == null) return;

    final bool? saved = await EditSellerProfileSheet.show(
      context,
      token: token,
      onSessionExpired: _forceRelogin,
    );
    if (saved != true || !mounted) return;

    setState(() => _account = SellerAuthController.instance.account);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('اطلاعات فروشگاه با موفقیت ذخیره شد.'),
        ),
      );
  }

  // ─────────── عملیات محصول ───────────

  /// افزودن محصول جدید (ویرایش → [_editProduct]).
  Future<void> _addProduct() async {
    final String? token = _token;
    if (token == null) return;

    final bool? saved = await ProductFormSheet.show(
      context,
      token: token,
      onSessionExpired: _forceRelogin,
    );
    if (saved == true) await _loadProducts();
  }

  /// ویرایش محصول انتخاب‌شده.
  Future<void> _editProduct(ProductModel product) async {
    final String? token = _token;
    if (token == null) return;

    final bool? saved = await ProductFormSheet.show(
      context,
      token: token,
      onSessionExpired: _forceRelogin,
      product: product,
    );
    if (saved == true) await _loadProducts();
  }

  /// حذف محصول (با تأیید) + حذف خوش‌بینانه از لیست.
  Future<void> _deleteProduct(ProductModel product) async {
    final bool? confirmed = await _showConfirmDialog(
      title: 'حذف محصول',
      message: 'آیا از حذف «${product.title}» مطمئن هستید؟ '
          'این عملیات قابل بازگشت نیست.',
      confirmLabel: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;
    if (!mounted) return; // دیالوگ ممکن است بعد از dispose بودن صفحه بسته شود

    // گرفتن messenger قبل از await (الگوی امن کل پروژه)
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _deletingProductId = product.id);

    try {
      await _repositoryLazy.deleteProduct(
        _token!,
        productId: product.id,
      );
      if (!mounted) return;
      setState(() {
        _deletingProductId = null;
        _products = _products
            .where((ProductModel item) => item.id != product.id)
            .toList();
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('محصول «${product.title}» حذف شد.')),
        );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _deletingProductId = null);
      // انقضای نشست (۴۰۱) → خروج اجباری + هدایت به صفحه ورود
      if (error.isSessionExpired) {
        await _forceRelogin();
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingProductId = null);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('حذف محصول انجام نشد؛ لطفاً دوباره تلاش کنید.'),
          ),
        );
    }
  }

  /// دیالوگ تأیید مشترک (خروج / حذف محصول).
  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actionsAlignment: MainAxisAlignment.start,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: isDestructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  // ─────────── UI ───────────

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // ── حالت آماده‌سازی (خواندن توکن از حافظه) ──
    if (_initializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('پنل فروشنده')),
        body: const LoadingView(label: 'در حال آماده‌سازی…'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل فروشنده'),
        actions: <Widget>[
          // دکمه خروج از دستگاه فعلی — هنگام انجام خروج: اسپینر
          if (_loggingOut)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
          else
            IconButton(
              onPressed: () => _logout(allDevices: false),
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'خروج از حساب',
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('افزودن محصول جدید'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 96),
          children: <Widget>[
            // ۱) هدر حساب فروشنده
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AccountHeader(
                account: _account,
                onEditProfile: _editProfile,
              ),
            ),
            const SizedBox(height: 20),

            // ۲) سرتیتر محصولات + شمارنده
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: AccentSectionTitle(title: 'محصولات من'),
                  ),
                  if (_products.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${toPersianDigits(_products.length.toString())} محصول',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ۳) حالت‌ها و لیست
            if (_loading && _products.isEmpty)
              const LoadingView(height: 220, label: 'در حال دریافت محصولات…')
            else if (_products.isEmpty && _error != null)
              ErrorView(
                height: 220,
                message: _error,
                onRetry: _loadProducts,
              )
            else if (_products.isEmpty)
              _EmptyProductsView(onAddTap: _addProduct)
            else
              ...<Widget>[
                for (final ProductModel product in _products)
                  PanelProductCard(
                    product: product,
                    isDeleting: _deletingProductId == product.id,
                    onTap: () => context.push(
                      AppRoutes.productDetailPath('${product.id}'),
                    ),
                    onEdit: () => _editProduct(product),
                    onDelete: () => _deleteProduct(product),
                  ),
              ],

            const SizedBox(height: 24),

            // ۴) خروج از همه دستگاه‌ها — پایان نشست حساب در تمام دستگاه‌ها
            //    (شامل همین دستگاه) از طریق logout-all.php
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                onTap: _loggingOut ? null : () => _logout(allDevices: true),
                enabled: !_loggingOut,
                leading: const Icon(
                  Icons.phonelink_erase_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'خروج از همه دستگاه‌ها',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'نشست این حساب در تمام دستگاه‌ها پایان داده می‌شود '
                  'و باید دوباره وارد شوید.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.7,
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

/// هدر حساب فروشنده در بالای پنل — لوگو، نام، نام کاربری، شهر، نشان تأیید
/// + دکمه «ویرایش اطلاعات فروشگاه».
class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.account,
    required this.onEditProfile,
  });

  /// اطلاعات حساب — ممکن است در حالت‌های خاص null باشد (فقط «فروشنده»)
  final SellerAccountModel? account;

  /// باز کردن شیت ویرایش اطلاعات فروشگاه
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final SellerAccountModel? seller = account;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            // ── لوگو / آواتار ──
            _buildAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'خوش آمدید',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // ── نام فروشگاه ──
                  Text(
                    seller?.name ?? 'فروشنده',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── نشان تأیید + نام کاربری + شهر ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (seller?.isVerified ?? false)
                        _MiniBadge(
                          icon: Icons.verified_rounded,
                          label: 'تأیید شده',
                          color: AppColors.success,
                        ),
                      if (seller?.username != null)
                        _MiniBadge(
                          icon: Icons.alternate_email_rounded,
                          label: seller!.username!,
                          color: AppColors.textSecondary,
                          isMonochrome: true,
                        ),
                      if (seller?.city != null)
                        _MiniBadge(
                          icon: Icons.location_on_outlined,
                          label: seller!.city!,
                          color: AppColors.textSecondary,
                          isMonochrome: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // ── دکمه ویرایش اطلاعات فروشگاه ──
            IconButton(
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primary,
              tooltip: 'ویرایش اطلاعات فروشگاه',
            ),
          ],
        ),
      ),
    );
  }

  /// آواتار دایره‌ای ۵۶ — لوگوی فروشگاه یا آیکون پیش‌فرض.
  Widget _buildAvatar() {
    final String? logoUrl = account?.logoUrl;
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl == null
          ? const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
              size: 28,
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, Object __, StackTrace? ___) => const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
    );
  }
}

/// نشان کوچک متن + آیکون (تأییدشده / نام کاربری / شهر).
class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.isMonochrome = false,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// نشان خنثی (خاکستری) — برای نام کاربری و شهر
  final bool isMonochrome;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color background = isMonochrome
        ? AppColors.border.withValues(alpha: 0.45)
        : color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// حالت خالی بودن لیست محصولات — پیام + دکمه افزودن اولین محصول.
class _EmptyProductsView extends StatelessWidget {
  const _EmptyProductsView({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: <Widget>[
            const EmptyView(
              height: 170,
              icon: Icons.inventory_2_outlined,
              message: 'هنوز محصولی ثبت نکرده‌اید.\n'
                  'اولین محصول خود را اضافه کنید.',
            ),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('افزودن اولین محصول'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
