import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'CompFlow'**
  String get appTitle;

  /// No description provided for @splashAppName.
  ///
  /// In ar, this message translates to:
  /// **'CompFlow'**
  String get splashAppName;

  /// No description provided for @splashLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get splashLoading;

  /// No description provided for @navDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get navDashboard;

  /// No description provided for @navPos.
  ///
  /// In ar, this message translates to:
  /// **'نقطة البيع'**
  String get navPos;

  /// No description provided for @navProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get navProducts;

  /// No description provided for @navSales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get navSales;

  /// No description provided for @navReports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get navReports;

  /// No description provided for @navUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get navUsers;

  /// No description provided for @navSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// No description provided for @headerSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث...'**
  String get headerSearchHint;

  /// No description provided for @headerNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get headerNotifications;

  /// No description provided for @headerProfile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get headerProfile;

  /// No description provided for @commonSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get commonDelete;

  /// No description provided for @commonSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get commonSearch;

  /// No description provided for @commonRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get commonClose;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In ar, this message translates to:
  /// **'الفرنسية'**
  String get settingsLanguageFrench;

  /// No description provided for @settingsThemeSection.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsThemeSection;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get settingsThemeLight;

  /// No description provided for @settingsAboutSection.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get settingsAboutSection;

  /// No description provided for @settingsAboutDescription.
  ///
  /// In ar, this message translates to:
  /// **'نظام إدارة متكامل لمحلات الكمبيوتر'**
  String get settingsAboutDescription;

  /// No description provided for @settingsVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get settingsVersion;

  /// No description provided for @dashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboardTitle;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In ar, this message translates to:
  /// **'اختصارات سريعة'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardNewSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع جديد'**
  String get dashboardNewSale;

  /// No description provided for @dashboardAddProduct.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get dashboardAddProduct;

  /// No description provided for @dashboardAddCustomer.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عميل'**
  String get dashboardAddCustomer;

  /// No description provided for @dashboardAddPurchase.
  ///
  /// In ar, this message translates to:
  /// **'إضافة شراء'**
  String get dashboardAddPurchase;

  /// No description provided for @dashboardAddExpense.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصروف'**
  String get dashboardAddExpense;

  /// No description provided for @dashboardSalesToday.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات اليوم'**
  String get dashboardSalesToday;

  /// No description provided for @dashboardSalesCountToday.
  ///
  /// In ar, this message translates to:
  /// **'عدد عمليات البيع اليوم'**
  String get dashboardSalesCountToday;

  /// No description provided for @dashboardPurchasesToday.
  ///
  /// In ar, this message translates to:
  /// **'مشتريات اليوم'**
  String get dashboardPurchasesToday;

  /// No description provided for @dashboardExpensesToday.
  ///
  /// In ar, this message translates to:
  /// **'مصروفات اليوم'**
  String get dashboardExpensesToday;

  /// No description provided for @dashboardNetProfitApprox.
  ///
  /// In ar, this message translates to:
  /// **'صافي الربح (تقريبي)'**
  String get dashboardNetProfitApprox;

  /// No description provided for @dashboardProductsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأصناف'**
  String get dashboardProductsCount;

  /// No description provided for @dashboardLowStockTitle.
  ///
  /// In ar, this message translates to:
  /// **'منتجات منخفضة المخزون'**
  String get dashboardLowStockTitle;

  /// No description provided for @dashboardLowStockEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات منخفضة المخزون حالياً.'**
  String get dashboardLowStockEmpty;

  /// No description provided for @dashboardRecentSalesTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر عمليات البيع'**
  String get dashboardRecentSalesTitle;

  /// No description provided for @dashboardRecentSalesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات بيع بعد.'**
  String get dashboardRecentSalesEmpty;

  /// No description provided for @dashboardUnknownCustomer.
  ///
  /// In ar, this message translates to:
  /// **'عميل غير معروف'**
  String get dashboardUnknownCustomer;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات بعد'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإضافة منتجات وتسجيل عمليات بيع لتظهر إحصائياتك هنا.'**
  String get dashboardEmptySubtitle;

  /// No description provided for @dashboardErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل لوحة التحكم'**
  String get dashboardErrorTitle;

  /// No description provided for @usersTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المستخدمين'**
  String get usersTitle;

  /// No description provided for @usersSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة حسابات المستخدمين وصلاحياتهم في النظام'**
  String get usersSubtitle;

  /// No description provided for @usersTotalCount.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المستخدمين'**
  String get usersTotalCount;

  /// No description provided for @usersActiveCount.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون النشطون'**
  String get usersActiveCount;

  /// No description provided for @usersSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم المستخدم أو البريد الإلكتروني...'**
  String get usersSearchHint;

  /// No description provided for @usersAddUser.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مستخدم'**
  String get usersAddUser;

  /// No description provided for @usersEditUser.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المستخدم'**
  String get usersEditUser;

  /// No description provided for @usersDeleteUser.
  ///
  /// In ar, this message translates to:
  /// **'حذف المستخدم'**
  String get usersDeleteUser;

  /// No description provided for @usersColumnName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get usersColumnName;

  /// No description provided for @usersColumnEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get usersColumnEmail;

  /// No description provided for @usersColumnRole.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get usersColumnRole;

  /// No description provided for @usersColumnStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get usersColumnStatus;

  /// No description provided for @usersColumnActions.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get usersColumnActions;

  /// No description provided for @usersStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get usersStatusActive;

  /// No description provided for @usersStatusInactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get usersStatusInactive;

  /// No description provided for @usersRoleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير النظام'**
  String get usersRoleAdmin;

  /// No description provided for @usersRoleManager.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get usersRoleManager;

  /// No description provided for @usersRoleCashier.
  ///
  /// In ar, this message translates to:
  /// **'أمين صندوق'**
  String get usersRoleCashier;

  /// No description provided for @usersEmptyList.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مستخدمون حالياً.'**
  String get usersEmptyList;

  /// No description provided for @usersDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف المستخدم؟'**
  String get usersDeleteConfirm;

  /// No description provided for @settingsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص مظهر التطبيق واللغات والخيارات العامة'**
  String get settingsSubtitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authLoginTitle;

  /// No description provided for @authEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmail;

  /// No description provided for @authEmailRequired.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال البريد الإلكتروني'**
  String get authEmailRequired;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPassword;

  /// No description provided for @authPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال كلمة المرور'**
  String get authPasswordRequired;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get authForgotPassword;

  /// No description provided for @authCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authCreateAccount;

  /// No description provided for @authRegisterTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authRegisterTitle;

  /// No description provided for @authFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get authFullName;

  /// No description provided for @authFullNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال الاسم الكامل'**
  String get authFullNameRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون 6 أحرف على الأقل'**
  String get authPasswordMinLength;

  /// No description provided for @authConfirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get authConfirmPassword;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء تأكيد كلمة المرور'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get authPasswordsMismatch;

  /// No description provided for @authResetPassword.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get authResetPassword;

  /// No description provided for @authSendResetLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط إعادة التعيين'**
  String get authSendResetLink;

  /// No description provided for @authInvalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صالح.'**
  String get authInvalidEmail;

  /// No description provided for @authUserDisabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تعطيل هذا الحساب.'**
  String get authUserDisabled;

  /// No description provided for @authUserNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مستخدم بهذا البريد الإلكتروني.'**
  String get authUserNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة.'**
  String get authWrongPassword;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد الإلكتروني مستخدم بالفعل.'**
  String get authEmailAlreadyInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ضعيفة جدًا.'**
  String get authWeakPassword;

  /// No description provided for @authOperationNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'هذه العملية غير مسموح بها حاليًا.'**
  String get authOperationNotAllowed;

  /// No description provided for @authInvalidCredential.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الاعتماد غير صالحة.'**
  String get authInvalidCredential;

  /// No description provided for @authTooManyRequests.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال عدد كبير من الطلبات، حاول لاحقًا.'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في الاتصال بالشبكة.'**
  String get authNetworkError;

  /// No description provided for @authUnexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع، حاول مرة أخرى.'**
  String get authUnexpectedError;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نظرة سريعة على أداء المحل والمبيعات والمخزون'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardChartTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحليل المبيعات'**
  String get dashboardChartTitle;

  /// No description provided for @dashboardChartSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات والمصروفات حسب الفترة'**
  String get dashboardChartSubtitle;

  /// No description provided for @dashboardDaily.
  ///
  /// In ar, this message translates to:
  /// **'يومي'**
  String get dashboardDaily;

  /// No description provided for @dashboardWeekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعي'**
  String get dashboardWeekly;

  /// No description provided for @dashboardMonthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get dashboardMonthly;

  /// No description provided for @dashboardYearly.
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get dashboardYearly;

  /// No description provided for @dashboardChartEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات كافية للرسم البياني'**
  String get dashboardChartEmpty;

  /// No description provided for @dashboardSalesLegend.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get dashboardSalesLegend;

  /// No description provided for @dashboardExpensesLegend.
  ///
  /// In ar, this message translates to:
  /// **'المصروفات'**
  String get dashboardExpensesLegend;

  /// No description provided for @dashboardLowStockQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية: {quantity} • الحد الأدنى: {minimum}'**
  String dashboardLowStockQuantity(Object minimum, Object quantity);

  /// No description provided for @dashboardSaleCustomerDate.
  ///
  /// In ar, this message translates to:
  /// **'{customer} • {date}'**
  String dashboardSaleCustomerDate(Object customer, Object date);

  /// No description provided for @customersTitle.
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get customersTitle;

  /// No description provided for @customersSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن عميل بالاسم...'**
  String get customersSearchHint;

  /// No description provided for @customersClearSearch.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get customersClearSearch;

  /// No description provided for @customersAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عميل'**
  String get customersAdd;

  /// No description provided for @customersInactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get customersInactive;

  /// No description provided for @customersLoadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل العملاء'**
  String get customersLoadError;

  /// No description provided for @customersNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get customersNoResults;

  /// No description provided for @customersEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عملاء بعد'**
  String get customersEmpty;

  /// No description provided for @customersSearchEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة بحث مختلفة أو تحقق من الإملاء.'**
  String get customersSearchEmptyHint;

  /// No description provided for @customersEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإضافة أول عميل لديك عبر زر الإضافة أسفل الشاشة.'**
  String get customersEmptyHint;

  /// No description provided for @commonRequiredField.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get commonRequiredField;

  /// No description provided for @commonInvalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير صالح'**
  String get commonInvalidEmail;

  /// No description provided for @customersEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل عميل'**
  String get customersEdit;

  /// No description provided for @customersPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get customersPhone;

  /// No description provided for @customersEmailOptional.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني (اختياري)'**
  String get customersEmailOptional;

  /// No description provided for @customersAddressOptional.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (اختياري)'**
  String get customersAddressOptional;

  /// No description provided for @customersNotesOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get customersNotesOptional;

  /// No description provided for @customersActive.
  ///
  /// In ar, this message translates to:
  /// **'عميل نشط'**
  String get customersActive;

  /// No description provided for @customersSaveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get customersSaveChanges;

  /// No description provided for @customersAddAction.
  ///
  /// In ar, this message translates to:
  /// **'إضافة العميل'**
  String get customersAddAction;

  /// No description provided for @productsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get productsTitle;

  /// No description provided for @productsSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتج بالاسم أو SKU...'**
  String get productsSearchHint;

  /// No description provided for @productsAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get productsAdd;

  /// No description provided for @productsSku.
  ///
  /// In ar, this message translates to:
  /// **'SKU: {sku}'**
  String productsSku(Object sku);

  /// No description provided for @productsQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية: {quantity}'**
  String productsQuantity(Object quantity);

  /// No description provided for @productsInactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get productsInactive;

  /// No description provided for @productsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل المنتجات'**
  String get productsLoadError;

  /// No description provided for @productsNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get productsNoResults;

  /// No description provided for @productsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات بعد'**
  String get productsEmpty;

  /// No description provided for @productsSearchEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة بحث مختلفة أو تحقق من الإملاء.'**
  String get productsSearchEmptyHint;

  /// No description provided for @productsEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإضافة أول منتج لديك عبر زر الإضافة أسفل الشاشة.'**
  String get productsEmptyHint;

  /// No description provided for @commonInvalidValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة غير صالحة'**
  String get commonInvalidValue;

  /// No description provided for @productsEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل منتج'**
  String get productsEdit;

  /// No description provided for @productsName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج'**
  String get productsName;

  /// No description provided for @productsBarcodeOptional.
  ///
  /// In ar, this message translates to:
  /// **'الباركود (اختياري)'**
  String get productsBarcodeOptional;

  /// No description provided for @productsPurchasePrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الشراء'**
  String get productsPurchasePrice;

  /// No description provided for @productsSalePrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر البيع'**
  String get productsSalePrice;

  /// No description provided for @productsQuantityLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get productsQuantityLabel;

  /// No description provided for @productsMinimum.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأدنى'**
  String get productsMinimum;

  /// No description provided for @productsCategoryOptional.
  ///
  /// In ar, this message translates to:
  /// **'معرّف الفئة (اختياري)'**
  String get productsCategoryOptional;

  /// No description provided for @productsActive.
  ///
  /// In ar, this message translates to:
  /// **'منتج نشط'**
  String get productsActive;

  /// No description provided for @productsAddAction.
  ///
  /// In ar, this message translates to:
  /// **'إضافة المنتج'**
  String get productsAddAction;

  /// No description provided for @posOutOfStock.
  ///
  /// In ar, this message translates to:
  /// **'المنتج غير متوفر في المخزون'**
  String get posOutOfStock;

  /// No description provided for @posStockExceeded.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تجاوز كمية المخزون'**
  String get posStockExceeded;

  /// No description provided for @posSaleSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إتمام البيع بنجاح'**
  String get posSaleSuccess;

  /// No description provided for @posLoadProductsError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل المنتجات'**
  String get posLoadProductsError;

  /// No description provided for @posSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم المنتج أو الباركود أو SKU...'**
  String get posSearchHint;

  /// No description provided for @posNoProducts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات'**
  String get posNoProducts;

  /// No description provided for @posCartTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلة المشتريات'**
  String get posCartTitle;

  /// No description provided for @posCartEmpty.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة'**
  String get posCartEmpty;

  /// No description provided for @posStock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون: {quantity}'**
  String posStock(Object quantity);

  /// No description provided for @posPerUnit.
  ///
  /// In ar, this message translates to:
  /// **'{price} دج / وحدة'**
  String posPerUnit(Object price);

  /// No description provided for @posTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get posTotal;

  /// No description provided for @posCompleteSale.
  ///
  /// In ar, this message translates to:
  /// **'إتمام البيع'**
  String get posCompleteSale;

  /// No description provided for @reportsToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get reportsToday;

  /// No description provided for @reportsWeek.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get reportsWeek;

  /// No description provided for @reportsMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get reportsMonth;

  /// No description provided for @reportsCustom.
  ///
  /// In ar, this message translates to:
  /// **'فترة مخصصة'**
  String get reportsCustom;

  /// No description provided for @reportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reportsTitle;

  /// No description provided for @reportsTotalSales.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات'**
  String get reportsTotalSales;

  /// No description provided for @reportsTotalPurchases.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشتريات'**
  String get reportsTotalPurchases;

  /// No description provided for @reportsTotalExpenses.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصروفات'**
  String get reportsTotalExpenses;

  /// No description provided for @reportsNetProfit.
  ///
  /// In ar, this message translates to:
  /// **'صافي الربح (تقريبي)'**
  String get reportsNetProfit;

  /// No description provided for @reportsSalesCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد عمليات البيع'**
  String get reportsSalesCount;

  /// No description provided for @reportsPurchasesCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد عمليات الشراء'**
  String get reportsPurchasesCount;

  /// No description provided for @reportsPeriod.
  ///
  /// In ar, this message translates to:
  /// **'الفترة: {range}'**
  String reportsPeriod(Object range);

  /// No description provided for @reportsProfitDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل صافي الربح التقريبي'**
  String get reportsProfitDetails;

  /// No description provided for @reportsSales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get reportsSales;

  /// No description provided for @reportsCogs.
  ///
  /// In ar, this message translates to:
  /// **'ناقص: تكلفة المبيعات (تقريبية)'**
  String get reportsCogs;

  /// No description provided for @reportsExpenses.
  ///
  /// In ar, this message translates to:
  /// **'ناقص: المصروفات'**
  String get reportsExpenses;

  /// No description provided for @reportsNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة: تكلفة المبيعات محسوبة بناءً على سعر الشراء الحالي لكل منتج، وليس السعر الفعلي وقت البيع، لأن هذه القيمة غير مُخزَّنة حالياً مع كل عملية بيع؛ لذا فالرقم تقريبي.'**
  String get reportsNote;

  /// No description provided for @reportsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل التقرير'**
  String get reportsLoadError;

  /// No description provided for @reportsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات في هذه الفترة'**
  String get reportsEmpty;

  /// No description provided for @reportsEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب اختيار فترة أخرى، أو ابدأ بتسجيل عمليات بيع أو شراء أو مصروفات.'**
  String get reportsEmptyHint;

  /// No description provided for @salesDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف عملية البيع'**
  String get salesDeleteTitle;

  /// No description provided for @salesDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف الفاتورة \"{invoice}\"؟'**
  String salesDeleteConfirm(Object invoice);

  /// No description provided for @salesDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الفاتورة \"{invoice}\"'**
  String salesDeleted(Object invoice);

  /// No description provided for @salesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get salesTitle;

  /// No description provided for @salesSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث برقم الفاتورة أو الملاحظات...'**
  String get salesSearchHint;

  /// No description provided for @salesCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء عملية بيع'**
  String get salesCreate;

  /// No description provided for @salesUnknownCustomer.
  ///
  /// In ar, this message translates to:
  /// **'عميل غير معروف ({id})'**
  String salesUnknownCustomer(Object id);

  /// No description provided for @salesInvoiceDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الفاتورة'**
  String get salesInvoiceDetails;

  /// No description provided for @salesDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ: {date}'**
  String salesDate(Object date);

  /// No description provided for @salesProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get salesProducts;

  /// No description provided for @salesLoadItemsError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل تفاصيل المنتجات: {error}'**
  String salesLoadItemsError(Object error);

  /// No description provided for @salesNoItems.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات مسجّلة لهذه الفاتورة.'**
  String get salesNoItems;

  /// No description provided for @salesQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية: {quantity} ×'**
  String salesQuantity(Object quantity);

  /// No description provided for @salesTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get salesTotal;

  /// No description provided for @salesNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get salesNotes;

  /// No description provided for @salesLoadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل عمليات البيع'**
  String get salesLoadError;

  /// No description provided for @salesNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get salesNoResults;

  /// No description provided for @salesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات بيع بعد'**
  String get salesEmpty;

  /// No description provided for @salesSearchEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة بحث مختلفة أو تحقق من الإملاء.'**
  String get salesSearchEmptyHint;

  /// No description provided for @salesEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بإنشاء أول عملية بيع عبر زر الإضافة أسفل الشاشة.'**
  String get salesEmptyHint;

  /// No description provided for @salesChooseProduct.
  ///
  /// In ar, this message translates to:
  /// **'اختر منتجاً'**
  String get salesChooseProduct;

  /// No description provided for @salesQuantityPositive.
  ///
  /// In ar, this message translates to:
  /// **'الكمية يجب أن تكون أكبر من صفر'**
  String get salesQuantityPositive;

  /// No description provided for @salesQuantityExceeded.
  ///
  /// In ar, this message translates to:
  /// **'الكمية المطلوبة ({requested}) تتجاوز الكمية المتاحة من \"{name}\" ({available}).'**
  String salesQuantityExceeded(Object available, Object name, Object requested);

  /// No description provided for @salesChooseCustomer.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار العميل'**
  String get salesChooseCustomer;

  /// No description provided for @salesAddItem.
  ///
  /// In ar, this message translates to:
  /// **'أضف منتجاً واحداً على الأقل'**
  String get salesAddItem;

  /// No description provided for @salesInvalidTotal.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الإجمالي غير صالحة'**
  String get salesInvalidTotal;

  /// No description provided for @salesLoginRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول لإنشاء عملية بيع'**
  String get salesLoginRequired;

  /// No description provided for @salesEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل عملية بيع'**
  String get salesEdit;

  /// No description provided for @salesCustomer.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get salesCustomer;

  /// No description provided for @salesLoadCustomersError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل العملاء: {error}'**
  String salesLoadCustomersError(Object error);

  /// No description provided for @salesInvoiceNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الفاتورة'**
  String get salesInvoiceNumber;

  /// No description provided for @salesDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البيع'**
  String get salesDateLabel;

  /// No description provided for @salesAddToInvoice.
  ///
  /// In ar, this message translates to:
  /// **'إضافة للفاتورة'**
  String get salesAddToInvoice;

  /// No description provided for @salesLoadProductsError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المنتجات: {error}'**
  String salesLoadProductsError(Object error);

  /// No description provided for @salesNoProductsAdded.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة منتجات بعد.'**
  String get salesNoProductsAdded;

  /// No description provided for @salesInvalidValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة غير صالحة'**
  String get salesInvalidValue;

  /// No description provided for @salesNotesOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get salesNotesOptional;

  /// No description provided for @salesCreateAction.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء عملية البيع'**
  String get salesCreateAction;

  /// No description provided for @pageExpenses.
  ///
  /// In ar, this message translates to:
  /// **'المصروفات'**
  String get pageExpenses;

  /// No description provided for @pageInventory.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get pageInventory;

  /// No description provided for @pageInvoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get pageInvoices;

  /// No description provided for @pagePayments.
  ///
  /// In ar, this message translates to:
  /// **'الدفعات'**
  String get pagePayments;

  /// No description provided for @pagePurchases.
  ///
  /// In ar, this message translates to:
  /// **'المشتريات'**
  String get pagePurchases;

  /// No description provided for @settingsLanguageArabicNative.
  ///
  /// In ar, this message translates to:
  /// **'العربية (Arabic)'**
  String get settingsLanguageArabicNative;

  /// No description provided for @currencyDzd.
  ///
  /// In ar, this message translates to:
  /// **'دج'**
  String get currencyDzd;

  /// No description provided for @posCompleteSaleError.
  ///
  /// In ar, this message translates to:
  /// **'فشل إتمام البيع: {error}'**
  String posCompleteSaleError(Object error);

  /// No description provided for @productsDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف \"{name}\"؟'**
  String productsDeleteConfirm(Object name);

  /// No description provided for @productsDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف \"{name}\"'**
  String productsDeleted(Object name);

  /// No description provided for @productsSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل حفظ المنتج: {error}'**
  String productsSaveFailed(Object error);

  /// No description provided for @customersDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف \"{name}\"؟'**
  String customersDeleteConfirm(Object name);

  /// No description provided for @customersDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف \"{name}\"'**
  String customersDeleted(Object name);

  /// No description provided for @customersSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل حفظ العميل: {error}'**
  String customersSaveFailed(Object error);

  /// No description provided for @salesSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل حفظ عملية البيع: {error}'**
  String salesSaveFailed(Object error);

  /// No description provided for @salesNoItemsError.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تحتوي عملية البيع على منتج واحد على الأقل'**
  String get salesNoItemsError;

  /// No description provided for @salesInvalidSaleTotalError.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي عملية البيع غير صالح'**
  String get salesInvalidSaleTotalError;

  /// No description provided for @salesInvalidItemPriceError.
  ///
  /// In ar, this message translates to:
  /// **'سعر أو إجمالي العنصر غير صالح'**
  String get salesInvalidItemPriceError;

  /// No description provided for @salesProductNotFoundError.
  ///
  /// In ar, this message translates to:
  /// **'المنتج غير موجود'**
  String get salesProductNotFoundError;

  /// No description provided for @salesInsufficientStockError.
  ///
  /// In ar, this message translates to:
  /// **'المخزون غير كافٍ للمنتج: {name}'**
  String salesInsufficientStockError(Object name);

  /// No description provided for @settingsLanguageEnglishNative.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglishNative;

  /// No description provided for @settingsLanguageFrenchNative.
  ///
  /// In ar, this message translates to:
  /// **'Français'**
  String get settingsLanguageFrenchNative;

  /// No description provided for @commonClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get commonClear;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
