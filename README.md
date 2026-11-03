# تجهیزیار 🛠️

**بازار آنلاین ابزار و تجهیزات صنعتی** — اپلیکیشن اندرویدی فروشگاهی (Marketplace) برای خرید و فروش ابزار، ماشین‌آلات و تجهیزات صنعتی بین فروشندگان و کارگاه‌ها.

## ویژگی‌های فاز فعلی (اسکلت پروژه)

- ✅ پروژه Flutter با **Material 3**
- ✅ کاملاً **راست‌چین (RTL)** و فارسی (`flutter_localizations` + `Directionality` اجباری)
- ✅ فونت فارسی **وزیرمتن (Vazirmatn)** از طریق پکیج `google_fonts`
- ✅ پالت رنگی اختصاصی برند در `lib/core/theme/app_colors.dart`
- ✅ تم سراسری در `lib/core/theme/app_theme.dart` (AppBar، کارت، دکمه، چیپ فیلتر، نوار ناوبری پایین و ...)
- ✅ مسیریابی اعلانی با **go_router** (شش صفحه + دو مسیر پارامتری)
- ✅ معماری Feature-First با لایه `core`
- ✅ **صفحه اصلی کامل:** دسته‌بندی‌ها (API)، بنر «پیشنهاد ویژه این هفته»، گرید محصولات جدید (API)
- ✅ **صفحه لیست محصولات کامل:** جستجوی زنده (debounce ۵۰۰ms)، صفحه‌بندی (اسکرول بی‌نهایت + دکمه «بارگذاری بیشتر»)، بنر تبلیغاتی بعد از هر ۵ محصول، آیتم محصول با دکمه «استعلام قیمت»
- ✅ **صفحه جزئیات محصول کامل:** گالری تصاویر با نشانگر نقطه‌ای، قیمت تقریبی + تاریخ شمسی + باکس هشدار، توضیحات، کارت فروشنده (کلیک → صفحه فروشنده)، دکمه‌های ثابت «تماس تلفنی» و «واتساپ» با `url_launcher`
- ✅ **صفحه فروشنده کامل:** هدر سرمه‌ای گرادیانی (لوگو، نام، شهر، نشان تأییدشده، توضیحات + دکمه‌های تماس)، لیست «محصولات این فروشنده» با آیتم مشترک، شمارنده فارسی، حالت‌های Loading / Error / Not Found / Empty
- ✅ **ورود فروشنده کامل:** فرم نام کاربری/رمز (نمایش/مخفی رمز)، اعتبارسنجی، حالت بارگذاری، پیام خطای فارسی سرور، ذخیره توکن + اطلاعات حساب در `shared_preferences`
- ✅ **پنل فروشنده کامل:** گارد توکن در روتر (بدون نشست → ورود)، هدر حساب با نشان تأییدشده، لیست محصولات خودم با ویرایش/حذف، فرم افزودن/ویرایش محصول (باتم‌شیت با فیلد دسته‌بندی از API)، خروج از حساب، مدیریت انقضای نشست (401 → هدایت به ورود)
- ✅ **کلاینت HTTP مشترک** (`core/network/api_client.dart`) با پشتیبانی هدر `Authorization: Bearer` و متدهای GET/POST/PUT/DELETE + ابزار مشترک تماس/واتساپ (`ContactLauncher` + `ContactButtonsRow`)
- ✅ **تاریخ شمسی:** تبدیل میلادی→جلالی بدون پکیج خارجی (`core/utils/jalali_date.dart`)
- ✅ مدیریت حالت‌های Loading / Error (با تلاش مجدد) / Empty + Pull-to-Refresh
- ✅ لایه داده با پکیج `http` + parse امن JSON (`core/utils/json_utils.dart`)

## پیش‌نیازها

| ابزار | نسخه |
|---|---|
| Flutter SDK | **3.27 یا جدیدتر** (برای `CardThemeData` و `Color.withValues`) |
| Dart | 3.6+ |
| Android SDK / Android Studio | جدید |

## راه‌اندازی

پوشه‌های پلتفرم (`android/` و ...) به‌دلیل عدم نصب Flutter SDK در محیط ساخت، تولید نشده‌اند. برای تولید آن‌ها **یک بار** دستور زیر را در ریشه پروژه اجرا کنید (فایل‌های موجود `lib/` و `pubspec.yaml` دست‌نخورده باقی می‌مانند):

```bash
flutter create . --project-name tajhizyar --org ir.tajhizyar --platforms android
```

سپس:

```bash
# دانلود پکیج‌ها
flutter pub get

# اجرا روی دستگاه / شبیه‌ساز اندروید
flutter run
```

### نکات مهم

1. **اسم اپ روی لانچر:** پس از اجرای `flutter create`، در فایل `android/app/src/main/AndroidManifest.xml` مقدار `android:label` را به `تجهیزیار` تغییر دهید.
2. **فونت در اجرای اول:** پکیج `google_fonts` در بارگذاری اول به اینترنت نیاز دارد و سپس فونت را کش می‌کند. برای انتشار نهایی و استفاده آفلاین، فایل‌های `Vazirmatn-*.ttf` را از [گیت‌هاب وزیرمتن](https://github.com/rastikerdar/vazirmatn) دانلود و در `assets/fonts/` قرار دهید و در `pubspec.yaml` ثبت کنید.
3. **فایل تست:** `test/widget_test.dart` فعلاً عمداً خالی است (فاز تست‌ها بعداً).
4. **مجوز اینترنت (Release):** بیلد دیباگ به‌صورت پیش‌فرض مجوز `INTERNET` دارد؛ برای انتشار، این خط را به `android/app/src/main/AndroidManifest.xml` اضافه کنید:
   `<uses-permission android:name="android.permission.INTERNET"/>`
5. **تماس و واتساپ (url_launcher):** برای اندروید ۱۱+ اگر از `canLaunchUrl` استفاده شود تعریف `<queries>` لازم است؛ در این پروژه فقط از `launchUrl` استفاده شده و نیازی به تغییر Manifest نیست.
6. **نشست فروشنده (shared_preferences):** توکن و اطلاعات حساب فروشنده روی حافظه محلی دستگاه ذخیره می‌شود؛ «خروج از حساب» و انقضای توکن (401 از سرور) هر دو نشست را پاک و کاربر را به صفحه ورود می‌برند.

## ساختار پروژه

```text
tajhizyar/
├── pubspec.yaml                      # وابستگی‌ها (go_router, google_fonts, http, url_launcher, shared_preferences)
├── analysis_options.yaml             # قوانین Lint
└── lib/
    ├── main.dart                     # نقطه ورود — MaterialApp.router + RTL + Locale fa
    ├── core/                         # لایه مشترک
    │   ├── constants/
    │   │   ├── app_constants.dart    # نام، شعار و نسخه اپ
    │   │   ├── app_routes.dart       # مسیرها/نام‌های صفحات + سازنده‌های مسیر
    │   │   └── api_constants.dart    # آدرس APIها + timeout + resolveUrl تصاویر
    │   ├── network/
    │   │   ├── api_client.dart        # کلاینت HTTP مشترک (timeout، UTF-8، خطاها، Bearer، GET/POST/PUT/DELETE)
    │   │   └── api_exception.dart    # خطای API با پیام فارسی + statusCode (تشخیص 401)
    │   ├── router/
    │   │   └── app_router.dart       # پیکربندی go_router
    │   ├── theme/
    │   │   ├── app_colors.dart       # پالت رنگ برند
    │   │   └── app_theme.dart        # تم Material 3
    │   ├── utils/
    │   │   ├── app_localizations.dart # تنظیمات بومی‌سازی فارسی
    │   │   ├── formatters.dart       # ارقام فارسی + قالب قیمت + normalizeDigits
    │   │   ├── jalali_date.dart      # تبدیل میلادی→شمسی (بدون پکیج خارجی)
    │   │   ├── phone_utils.dart      # نرمال‌سازی شماره واتساپ (قالب بین‌المللی)
    │   │   ├── contact_launcher.dart # تماس/واتساپ مشترک (url_launcher + SnackBar)
    │   │   └── json_utils.dart       # parse امن JSON (int/string/bool)
    │   └── widgets/                  # ویجت‌های مشترک
    │       ├── loading_view.dart
    │       ├── error_view.dart       # با دکمه «تلاش مجدد»
    │       ├── empty_view.dart
    │       ├── accent_section_title.dart # عنوان بخش با نوار نارنجی
    │       └── contact_buttons_row.dart  # ردیف دکمه‌های تماس/واتساپ
    └── features/                     # Feature-First
        ├── home/
        │   └── presentation/
        │       ├── pages/home_screen.dart
        │       └── widgets/          # HomeAppBar, CategoryStrip, CategoryItem,
        │                             # PromoBanner, SectionHeader, ProductCard
        ├── products/
        │   ├── data/                 # مالک داده محصول/دسته‌بندی (مشترک با home)
        │   │   ├── models/category_model.dart
        │   │   ├── models/product_model.dart        # فیلدهای مشترک لیست
        │   │   ├── models/product_detail_model.dart # جزئیات + اطلاعات کامل فروشنده
        │   │   └── products_repository.dart  # fetchCategories + fetchProducts + fetchProductDetail
        │   └── presentation/
        │       ├── pages/
        │       │   ├── product_list_screen.dart    # جستجو + صفحه‌بندی + بنر
        │       │   └── product_detail_screen.dart  # گالری + قیمت + هشدار + تماس
        │       └── widgets/
        │           ├── accent_section_title.dart    # عنوان بخش با نوار نارنجی
        │           ├── product_image_gallery.dart   # PageView + نشانگر dots
        │           ├── product_info_section.dart    # عنوان/برند/قیمت/هشدار
        │           ├── product_description_section.dart
        │           ├── seller_info_card.dart        # کلیک → صفحه فروشنده
        │           ├── product_contact_bar.dart     # تماس تلفنی / واتساپ
        │           ├── product_list_item.dart       # آیتم افقی قابل استفاده مجدد
        │           └── product_list_promo_banner.dart
        └── seller/
            ├── data/
            │   ├── models/seller_model.dart         # پروفایل عمومی + محصولات فروشنده
            │   ├── models/seller_account_model.dart # حساب فروشنده لاگین‌شده
            │   ├── seller_repository.dart           # fetchSeller (ApiClient مشترک)
            │   ├── seller_auth_storage.dart         # توکن/حساب در shared_preferences
            │   ├── seller_auth_repository.dart      # ورود (login.php)
            │   └── seller_panel_repository.dart     # محصولات خودم: لیست/حذف/افزودن/ویرایش
            └── presentation/
                ├── pages/
                │   ├── seller_screen.dart       # هدر + محصولات + ۵ حالت
                │   ├── seller_login_screen.dart # فرم ورود + ذخیره نشست
                │   └── seller_panel_screen.dart # هدر حساب + مدیریت محصولات + خروج
                └── widgets/
                    ├── seller_header.dart       # هدر سرمه‌ای گرادیانی
                    ├── panel_product_card.dart  # کارت مدیریت محصول (ویرایش/حذف)
                    └── product_form_sheet.dart  # باتم‌شیت افزودن/ویرایش محصول
```

## پالت رنگی برند

| نقش | کد | نمونه استفاده |
|---|---|---|
| Primary (آبی نفتی تیره) | `#1E3A5F` | AppBar، ناوبری انتخاب‌شده، عناوین |
| Secondary (نارنجی گرم) | `#F59E0B` | دکمه اصلی، قیمت، برچسب تخفیف |
| Background | `#F8FAFC` | پس‌زمینه صفحه‌ها |
| Surface / Card | `#FFFFFF` | کارت‌ها و کانتینرها |
| Text Primary | `#1E293B` | متن اصلی |
| Text Secondary | `#64748B` | متن فرعی و توضیحات |

## نقشه مسیرها (go_router)

| مسیر | صفحه | پارامتر |
|---|---|---|
| `/` | HomeScreen | — |
| `/products` | ProductListScreen | — |
| `/products/:productId` | ProductDetailScreen | `productId` |
| `/sellers/:sellerId` | SellerScreen | `sellerId` |
| `/seller/login` | SellerLoginScreen | — (لاگین‌شده → پنل) |
| `/seller/panel` | SellerPanelScreen | — (بدون توکن → ورود) |

نمونه ناوبری:

```dart
context.push(AppRoutes.productDetailPath('42'));
context.go(AppRoutes.sellerPanel);
```

## نقشه راه (فازهای بعدی)

- [x] صفحه اصلی: دسته‌بندی‌ها (API)، بنر پیشنهاد ویژه، محصولات جدید (API) — نوار ناوبری پایین در فاز بعدی
- [x] لیست محصولات: ListView عمودی، جستجوی زنده، صفحه‌بندی، بنر تبلیغاتی بین آیتم‌ها، استعلام قیمت
- [x] جزئیات محصول: گالری تصاویر با dots، قیمت ترفیعی + تاریخ شمسی، باکس هشدار، اطلاعات فروشنده، دکمه‌های تماس/واتساپ
- [x] فروشگاه: هدر فروشنده (لوگو، شهر، تأییدشده، توضیحات، تماس) + لیست محصولاتش
- [x] ورود و پنل فروشنده: احراز هویت (توکن در shared_preferences)، مدیریت محصولات (لیست/حذف کامل + افزودن/ویرایش اسکلت)
- [ ] تکمیل فرم افزودن/ویرایش (گالری تصاویر، اعتبارسنجی سمت سرور) و نوار ناوبری پایین
- [ ] اتصال به بک‌اند (REST API) و مدیریت استت (Riverpod / Bloc)
