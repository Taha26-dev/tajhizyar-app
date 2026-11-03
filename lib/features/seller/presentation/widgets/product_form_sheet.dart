import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/core/widgets/form_error_box.dart';
import 'package:tajhizyar/features/products/data/models/category_model.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';
import 'package:tajhizyar/features/products/data/products_repository.dart';
import 'package:tajhizyar/features/seller/data/seller_panel_repository.dart';
import 'package:tajhizyar/features/seller/presentation/widgets/product_images_section.dart';

/// باتم‌شیت فرم افزودن/ویرایش محصول — «اسکلت» فاز فعلی.
///
/// فیلدها: عنوان (اجباری)، دسته‌بندی (از API دسته‌ها)، قیمت تومان
/// (خالی = توافقی)، برند و توضیحات (اختیاری) + تصاویر محصول
/// (حداکثر ۳ عکس — آپلود multipart پیش از ثبت؛ بخش [ProductImagesSection]).
///
/// - افزودن: `POST /api/seller/products.php` — بدون هیچ id (URL و بدنه)
/// - ویرایش: `PUT /api/seller/product.php?id={id}`
///   (در حالت ویرایش، توضیحات فعلی محصول از API لیست در دسترس نیست؛
///   در صورت پر کردن فیلد، توضیحات بازنویسی می‌شود — helper زیر فیلد)
///
/// نتیجه بستن شیت: `true` یعنی ذخیره موفق بود (صفحه پنل لیست را
/// refresh می‌کند)؛ `false`/null یعنی انصراف یا خطای نشست.
class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({
    super.key,
    required this.token,
    required this.onSessionExpired,
    this.product,
  });

  /// توکن نشست فروشنده (از صفحه پنل پاس داده می‌شود)
  final String token;

  /// محصول برای حالت ویرایش — null یعنی «افزودن محصول جدید»
  final ProductModel? product;

  /// هنگام 401 (انقضای نشست) فراخوانی می‌شود تا صفحه پنل
  /// کاربر را به صفحه ورود هدایت کند.
  final VoidCallback onSessionExpired;

  /// نمایش شیت و برگرداندن نتیجه ذخیره.
  static Future<bool?> show(
    BuildContext context, {
    required String token,
    required VoidCallback onSessionExpired,
    ProductModel? product,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => ProductFormSheet(
        token: token,
        onSessionExpired: onSessionExpired,
        product: product,
      ),
    );
  }

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  late final bool _isEditing = widget.product != null;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.product?.title ?? '');
  late final TextEditingController _priceController = TextEditingController(
    text: (widget.product != null && widget.product!.price > 0)
        ? widget.product!.price.toString()
        : '',
  );
  late final TextEditingController _brandController =
      TextEditingController(text: widget.product?.brand ?? '');
  final TextEditingController _descriptionController = TextEditingController();

  // ── دسته‌بندی‌ها (از API مشترک) ──
  ProductsRepository? _categoriesRepository;
  late Future<List<CategoryModel>> _categoriesFuture = _loadCategories();
  int? _selectedCategoryId;
  bool _categoriesFailed = false;

  // ── ارسال ──
  SellerPanelRepository? _panelRepository;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ── تصاویر محصول ──
  /// URLهای آماده ارسال (آپلودشده‌های موفق) — از بخش تصاویر به‌روز می‌شود
  List<String> _imageUrls = <String>[];

  /// آیا حداقل یک تصویر در حال آپلود است؟ (قفل دکمه ذخیره)
  bool _imagesBusy = false;

  @override
  void initState() {
    super.initState();
    // در حالت ویرایش، تصاویر فعلی محصول نقطه شروع هستند
    _imageUrls = widget.product?.imageUrls.toList() ?? <String>[];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _categoriesRepository?.dispose();
    _panelRepository?.dispose();
    super.dispose();
  }

  SellerPanelRepository get _panelLazy => _panelRepository ??= SellerPanelRepository();

  Future<List<CategoryModel>> _loadCategories() async {
    _categoriesRepository ??= ProductsRepository();
    try {
      final List<CategoryModel> categories =
          await _categoriesRepository!.fetchCategories();
      _categoriesFailed = false;
      // در حالت ویرایش، دسته ذخیره‌شده محصول را از پیش انتخاب کن
      if (_selectedCategoryId == null && _isEditing) {
        final int? saved = widget.product!.categoryId;
        if (saved != null &&
            categories.any((CategoryModel c) => c.id == saved)) {
          _selectedCategoryId = saved;
        }
      }
      return categories;
    } on ApiException {
      _categoriesFailed = true;
      rethrow;
    }
  }

  void _reloadCategories() {
    setState(() => _categoriesFuture = _loadCategories());
  }

  // ─────────── ذخیره ───────────

  Future<void> _submit() async {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // آپلود تصاویر هنوز در جریان است؟
    if (_imagesBusy) {
      setState(() {
        _errorMessage = 'لطفاً تا پایان آپلود تصاویر صبر کنید.';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    final int price = _parsedPrice;

    try {
      if (_isEditing) {
        await _panelLazy.updateProduct(
          widget.token,
          productId: widget.product!.id,
          title: _titleController.text,
          categoryId: _selectedCategoryId,
          price: price,
          brand: _brandController.text,
          description: _descriptionController.text,
          imageUrls: _imageUrls,
        );
      } else {
        await _panelLazy.addProduct(
          widget.token,
          title: _titleController.text,
          categoryId: _selectedCategoryId,
          price: price,
          brand: _brandController.text,
          description: _descriptionController.text,
          imageUrls: _imageUrls,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true); // موفق → پنل لیست را refresh می‌کند
    } on ApiException catch (error) {
      if (!mounted) return;
      // انقضای نشست (۴۰۱) → بستن شیت و هدایت به صفحه ورود
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
        _errorMessage = 'ذخیره محصول انجام نشد؛ لطفاً دوباره تلاش کنید.';
      });
    }
  }

  /// انقضای نشست در حین آپلود تصویر — بستن شیت و هدایت به صفحه ورود
  void _expireFromImages() {
    if (!mounted) return;
    Navigator.of(context).pop(false);
    widget.onSessionExpired();
  }

  /// parse امن قیمت — ارقام فارسی/جداکننده‌ها پاک می‌شوند؛ خالی → 0 (توافقی)
  int get _parsedPrice {
    final String digits = normalizeDigits(_priceController.text)
        .replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
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
          child: SingleChildScrollView(
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

                  // ── عنوان ──
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    enabled: !_isSubmitting,
                    maxLength: 120,
                    buildCounter: (
                      BuildContext context, {
                      required int currentLength,
                      required bool isFocused,
                      int? maxLength,
                    }) =>
                        null, // شمارنده پیش‌فرض مخفی
                    decoration: const InputDecoration(
                      labelText: 'عنوان محصول *',
                      hintText: 'مثلاً: دریل چکشی بوش ۸۰۰ وات',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'عنوان محصول را وارد کنید.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── دسته‌بندی ──
                  _buildCategoryField(),
                  const SizedBox(height: 16),

                  // ── قیمت ──
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    enabled: !_isSubmitting,
                    inputFormatters: <TextInputFormatter>[
                      _PriceInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'قیمت (تومان)',
                      hintText: 'خالی = قیمت توافقی',
                      prefixIcon: Icon(Icons.payments_outlined),
                      helperText: 'اگر قیمت ثابت ندارد، خالی بگذارید.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── برند ──
                  TextFormField(
                    controller: _brandController,
                    textInputAction: TextInputAction.next,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'برند',
                      hintText: 'مثلاً: بوش',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── تصاویر محصول (حداکثر ۳ عکس) ──
                  ProductImagesSection(
                    token: widget.token,
                    repository: _panelLazy,
                    initialImageUrls:
                        widget.product?.imageUrls ?? const <String>[],
                    enabled: !_isSubmitting,
                    onChanged: (List<String> urls) => _imageUrls = urls,
                    onUploadBusyChanged: (bool busy) => _imagesBusy = busy,
                    onSessionExpired: _expireFromImages,
                  ),
                  const SizedBox(height: 16),

                  // ── توضیحات ──
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'توضیحات',
                      hintText: 'مشخصات فنی، شرایط فروش و ...',
                      alignLabelWithHint: true,
                      helperText: _isEditing
                          ? 'توضیحات فعلی از لیست در دسترس نیست؛ '
                              'در صورت پر کردن، بازنویسی می‌شود.'
                          : null,
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
                              : Text(
                                  _isEditing
                                      ? 'ذخیره تغییرات'
                                      : 'افزودن محصول',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
            Icon(
              _isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
              color: AppColors.secondary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isEditing ? 'ویرایش محصول' : 'افزودن محصول جدید',
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

  /// فیلد دسته‌بندی — Dropdown با بارگذاری از API (حالت خطا + تلاش مجدد)
  Widget _buildCategoryField() {
    return FutureBuilder<List<CategoryModel>>(
      future: _categoriesFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<CategoryModel>> snapshot,
      ) {
        final bool loading = snapshot.connectionState == ConnectionState.waiting;

        // ── حالت خطا: پیام + تلاش مجدد ──
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.category_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // پیام استاندارد فارسی از لایه شبکه
                    apiErrorMessage(snapshot.error),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: _isSubmitting ? null : _reloadCategories,
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<int>(
          value: _selectedCategoryId,
          items: loading
              ? null
              : <DropdownMenuItem<int>>[
                  for (final CategoryModel category in snapshot.data ?? const <CategoryModel>[])
                    DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
          onChanged: _isSubmitting
              ? null
              : (int? value) => setState(() => _selectedCategoryId = value),
          decoration: InputDecoration(
            labelText: 'دسته‌بندی',
            prefixIcon: const Icon(Icons.category_outlined),
            suffixIcon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
            helperText: _categoriesFailed
                ? 'بدون دسته‌بندی هم می‌توانید ادامه دهید.'
                : null,
          ),
        );
      },
    );
  }
}

/// فرمت‌کننده قیمت — ارقام فارسی/عربی را به لاتین تبدیل و
/// فقط اجازه ارقام را می‌دهد (برای parse امن).
class _PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String normalized = normalizeDigits(newValue.text)
        .replaceAll(RegExp(r'[^0-9]'), '');
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}
