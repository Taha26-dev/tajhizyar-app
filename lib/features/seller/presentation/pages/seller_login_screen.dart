import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_constants.dart';
import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/constants/error_messages.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/widgets/form_error_box.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_controller.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_repository.dart';

/// صفحه ورود فروشنده — مسیر `/seller/login`.
///
/// بخش‌ها:
///  ۱. هدر برند: آیکون فروشگاه + «ورود فروشندگان» + توضیح کوتاه
///  ۲. فرم ورود: نام کاربری + رمز عبور (با دکمه نمایش/مخفی)
///  ۳. دکمه «ورود» با حالت بارگذاری + باکس پیام خطا
///
/// پس از ورود موفق: نشست با [SellerAuthController] ذخیره و کاربر
/// به پنل فروشنده (همان تب ۳) هدایت می‌شود. (اگر از قبل لاگین باشد،
/// ردایرکت روتر او را مستقیم به پنل می‌برد.)
class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  SellerAuthRepository? _repository;

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  /// پیام خطای فرم (از سرور یا اعتبارسنجی محلی) — null یعنی بدون خطا
  String? _errorMessage;

  /// ساخت تنبل ریپازیتوری — فقط وقتی درخواست واقعی داریم ساخته می‌شود.
  SellerAuthRepository get _repositoryLazy =>
      _repository ??= SellerAuthRepository();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    _repository?.dispose();
    super.dispose();
  }

  // ─────────── منطق ورود ───────────

  Future<void> _submit() async {
    // خطای قبلی پاک می‌شود تا بازگشت تمرکز، باکس خطا را مخفی کند
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final SellerAuthResult result = await _repositoryLazy.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      // ── ثبت نشست (ذخیره دائمی + کش حافظه برای گارد روتر و UI) ──
      // توکن عیناً ذخیره می‌شود و expires_at (در صورت وجود در پاسخ)
      // هم کنار آن نگهداری می‌شود.
      await SellerAuthController.instance.signIn(
        token: result.token,
        account: result.account,
        expiresAt: result.expiresAt,
      );

      if (!mounted) return;

      // رفتن به پنل — `go` (نه push) تا «بازگشت» به صفحه ورود ممکن نباشد.
      context.go(AppRoutes.sellerPanel);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        // پیام فارسی سرور («نام کاربری یا رمز عبور اشتباه است» و ...)
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = ErrorMessages.unknown;
      });
    }
  }

  // ─────────── UI ───────────

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('ورود فروشنده')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildBrandHeader(textTheme),
                    const SizedBox(height: 24),

                    // ── کارت فرم ──
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (_errorMessage != null) ...<Widget>[
                              FormErrorBox(message: _errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              enabled: !_isSubmitting,
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                              decoration: const InputDecoration(
                                labelText: 'نام کاربری',
                                hintText: 'نام کاربری فروشگاه',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                ),
                              ),
                              validator: (String? value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'نام کاربری را وارد کنید.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              enabled: !_isSubmitting,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'رمز عبور',
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                // دکمه نمایش/مخفی کردن رمز
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword =
                                        !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  tooltip: _obscurePassword
                                      ? 'نمایش رمز عبور'
                                      : 'مخفی کردن رمز عبور',
                                ),
                              ),
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'رمز عبور را وارد کنید.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // ── دکمه ورود ──
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmitting ? null : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.login_rounded,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('ورود'),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── لینک ثبت‌نام (فعلاً «به‌زودی») ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'حساب فروشندگی ندارید؟',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: _showRegisterSoon,
                          child: const Text('ثبت‌نام فروشنده'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// هدر برند بالای فرم — لوگوی اپ + عنوان
  Widget _buildBrandHeader(TextTheme textTheme) {
    return Column(
      children: <Widget>[
        Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Image.asset(
            'assets/icons/logo.png',
            fit: BoxFit.contain,
            semanticLabel: 'لوگوی تجهیزیار',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ورود فروشندگان ${AppConstants.appName}',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'برای مدیریت محصولات و فروشگاه خود وارد شوید.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  void _showRegisterSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('ثبت‌نام فروشندگان به‌زودی فعال می‌شود.'),
        ),
      );
  }
}
