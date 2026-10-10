import 'package:flutter/material.dart';

final appLocale = ValueNotifier<Locale?>(null);

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ar'), Locale('en')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isArabic => locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  String text(String arabic) =>
      isArabic ? arabic : _englishTranslations[arabic] ?? arabic;

  String digits(Object value) {
    final source = value.toString();
    const easternToWestern = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };
    const westernToEastern = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return source.replaceAllMapped(
      RegExp(isArabic ? r'[0-9]' : r'[٠-٩]'),
      (match) => (isArabic ? westernToEastern : easternToWestern)[match[0]]!,
    );
  }

  static const _englishTranslations = <String, String>{
    'أهلاً بك': 'Welcome back',
    'تسجيل الخروج': 'Sign out',
    'تسجيل الدخول يحتاج إلى إعداد Firebase قبل استخدامه.':
        'Firebase must be configured before phone sign-in is available.',
    'إعداد Firebase مطلوب': 'Firebase setup required',
    'لم يتم إعداد Firebase لهذا التطبيق بعد. أضف بيانات Firebase الخاصة بتطبيق Android أو iOS إلى خيارات البناء ثم أعد تشغيل التطبيق.':
        'Firebase is not configured for this app. Add the Android or iOS Firebase dart-defines to the build command, then restart the app.',
    'تسجيل الدخول': 'Sign in',
    'تحقق من رقم هاتفك': 'Verify your phone number',
    'وثّق رقم هاتفك لإكمال تسجيل Google':
        'Verify your phone number to finish Google sign-in',
    'أرسل رمزاً لمرة واحدة إلى هاتفك لتسجيل الدخول بأمان.':
        'We will send a one-time code to your phone to sign in securely.',
    'اربط رقم هاتف موثّق بحساب Google حتى تتمكن من استخدام خدمات التطبيق.':
        'Link a verified phone number to Google to use the app services.',
    'اربط رقم هاتف موثق بحسابك لإكمال تسجيل الدخول.':
        'Link a verified phone number to complete sign-in.',
    'المتابعة باستخدام Google': 'Continue with Google',
    'أو برقم الهاتف': 'or with phone',
    'تعذر تسجيل الدخول باستخدام Google': 'Could not sign in with Google',
    'تعذر إكمال تسجيل الدخول': 'Could not complete sign-in',
    'هذا الرقم أو البريد مرتبط بحساب آخر. سجّل الدخول بالطريقة المرتبط بها الحساب أولاً.':
        'This phone or email belongs to another account. Sign in with its existing method first.',
    'اربط رقم هاتفك لمتابعة استخدام التطبيق':
        'Link your phone number to continue using the app',
    'رقم الهاتف': 'Phone number',
    'أوافق على استخدام رقم الهاتف للتحقق':
        'I agree to use my phone number for verification',
    'تُرسل أرقام الهاتف إلى Google وتُخزّن لديها للمساعدة في منع الرسائل المزعجة وإساءة الاستخدام.':
        'Google receives and stores phone numbers to help prevent spam and abuse.',
    'وافق على استخدام رقمك للتحقق':
        'Please agree to phone verification before continuing.',
    'أدخل رقم مصر بصيغة 01XXXXXXXXX أو الرقم الدولي بصيغة +':
        'Enter an Egyptian mobile number starting with 01, or an international number starting with +.',
    'إرسال رمز التحقق': 'Send verification code',
    'إعادة إرسال الرمز': 'Resend code',
    'يمكنك إعادة الإرسال بعد': 'You can resend in',
    'ثانية': 'seconds',
    'أدخل رمز التحقق المكوّن من ٦ أرقام': 'Enter the 6-digit verification code',
    'تأكيد الرمز': 'Verify code',
    'تغيير رقم الهاتف': 'Change phone number',
    'رقم الهاتف غير صحيح': 'The phone number is invalid',
    'رمز التحقق غير صحيح': 'The verification code is incorrect',
    'انتهت صلاحية الرمز، أرسل رمزاً جديداً':
        'The code expired. Request a new code.',
    'طلبات كثيرة، انتظر قليلاً ثم حاول مجدداً':
        'Too many attempts. Wait a moment and try again.',
    'تحقق من اتصال الإنترنت وحاول مرة أخرى':
        'Check your internet connection and try again.',
    'تعذر التحقق الأمني، حاول مرة أخرى':
        'Security verification failed. Please try again.',
    'تعذر تسجيل الدخول، تحقق من بياناتك وحاول مرة أخرى':
        'Could not sign in. Check your information and try again.',
    'تعذر إرسال رمز التحقق، حاول مرة أخرى':
        'Could not send the verification code. Please try again.',
    'أعد إرسال رمز التحقق': 'Request a new verification code',
    'تعذر التحقق من الرمز، حاول مرة أخرى':
        'Could not verify the code. Please try again.',
    'تم تسجيل الدخول بنجاح': 'Signed in successfully',
    'تم تسجيل الدخول، لكن تعذر الاتصال بالخادم حالياً':
        'You are signed in, but the server is currently unavailable.',
    'تحتاج إلى تسجيل الدخول لإرسال طلب الانضمام.':
        'Sign in to send a join request.',
    'أدخل قيمة المساهمة التي تتوقعها. إرسال الطلب لا يستقبل أموالاً ولا ينشئ التزاماً مالياً.':
        'Enter your expected contribution. The request does not collect money or create a financial commitment.',
    'مبلغ مساهمتك المتوقعة': 'Your expected contribution',
    'أدخل مبلغاً يساوي الحد الأدنى أو يزيد عليه.':
        'Enter an amount equal to or greater than the minimum.',
    'إلغاء': 'Cancel',
    'إرسال الطلب': 'Submit request',
    'تم إرسال طلب الانضمام للمراجعة. لا يتم تحصيل أي أموال.':
        'Your join request was submitted for review. No money is collected.',
    'تعذر إرسال الطلب الآن. تحقق من اتصال الخادم وحاول مجدداً.':
        'Could not send your request. Check the server connection and try again.',
    'المشروع غير متاح للانضمام': 'This project is not accepting requests',
    'بيت كو': 'BaitCo',
    'مفتاحك لبيت مستدام': 'Your key to a sustainable home',
    'العقارات تبدأ من هنا': 'Your property journey starts here',
    'شعار بيت كو': 'BaitCo logo',
    'بيتك يبدأ بخطوة': 'Your home starts with one step',
    'تحديث البيانات': 'Refresh listings',
    'الإشعارات': 'Notifications',
    'لا توجد إشعارات جديدة حالياً': 'No new notifications',
    'أنشئ مشروعاً': 'Create a project',
    'أضف عقارك': 'Add a property',
    'العقارات': 'Properties',
    'الشراكات': 'Partnerships',
    'المفضلة': 'Favorites',
    'حسابي': 'My account',
    'عقاراتك المفضلة': 'Your favorite properties',
    'الإعلانات التي حفظتها للرجوع إليها': 'Listings you saved for later',
    'شراكات متاحة': 'Available partnerships',
    'فرص البناء المشترك': 'Co-building opportunities',
    'عقارات مميزة': 'Featured properties',
    'اختيارات مناسبة لك': 'Places you may like',
    'لم تحفظ أي عقار بعد': 'You have not saved a property yet',
    'لا توجد نتائج مطابقة': 'No matching results',
    'استثمروا في مستقبل مشترك': 'Build a future together',
    'من المالك إليك مباشرة': 'Directly from property owners',
    'ابنِ بيتك مع شركاء تثق بهم': 'Build your home with trusted partners',
    'اعثر على بيتك القادم': 'Find your next home',
    'تابع التكلفة والمراحل والحصص بوضوح.':
        'Track costs, stages, and shares clearly.',
    'تصفح إعلانات مباشرة بلا تعقيد.': 'Browse property listings with ease.',
    'مشاريع نشطة': 'Active projects',
    'عقارات متاحة': 'Available properties',
    'شركاء': 'Partners',
    'مناطق': 'Areas',
    'وضع معاينة: الخادم غير متصل، نعرض بيانات تجريبية.':
        'Preview mode: the server is offline, so sample listings are shown.',
    'ابحث عن عقار أو منطقة': 'Search properties or areas',
    'ابحث عن مشروع أو منطقة': 'Search projects or areas',
    'تصفية النتائج': 'Filter results',
    'الكل': 'All',
    'شقق': 'Apartments',
    'أراضٍ': 'Land',
    'السعر': 'Price',
    'تصفية العقارات': 'Filter properties',
    'نوع العقار': 'Property type',
    'الحد الأقصى للسعر': 'Maximum price',
    'إعادة ضبط': 'Reset',
    'عرض النتائج': 'Show results',
    'حتى ٢ مليون': 'Up to EGP 2 million',
    'حتى ٥ ملايين': 'Up to EGP 5 million',
    'كل الأسعار': 'Any price',
    'عرض الكل': 'See all',
    'قيد المراجعة': 'Under review',
    'إعلان موثق': 'Published listing',
    'منشور': 'Published',
    'إضافة إلى المفضلة': 'Add to favorites',
    'إزالة من المفضلة': 'Remove from favorites',
    'اكتمال المساهمات': 'Contribution progress',
    'مسح البحث والفلاتر': 'Clear search and filters',
    'مرحباً بك في بيت كو': 'Welcome to BaitCo',
    'سجّل الدخول لإدارة إعلاناتك وطلباتك':
        'Sign in to manage your listings and requests',
    'سيتم تفعيل تسجيل الدخول في المرحلة التالية':
        'Phone sign-in will be available in the next release step',
    'تسجيل الدخول برقم الهاتف': 'Sign in with phone',
    'إعلاناتي': 'My listings',
    'إدارة العقارات التي أضفتها': 'Manage properties you have posted',
    'مشاريعي وطلباتي': 'My projects and requests',
    'متابعة الشراكات وطلبات الانضمام': 'Track partnerships and join requests',
    'المساعدة والدعم': 'Help and support',
    'تواصل مع فريق بيت كو': 'Contact the BaitCo team',
    'سجّل الدخول للوصول إلى هذه الصفحة': 'Sign in to access this page',
    'أُضيف العقار إلى المفضلة': 'Added to favorites',
    'جنيه': 'EGP',
    'تواصل مباشر مع المالك': 'Contact the owner directly',
    'تفاصيل العقار': 'Property details',
    'تفاصيل ومعلومات العقار مقدمة من المالك. ننصح بمعاينة الوحدة والتحقق من المستندات قبل إتمام أي اتفاق.':
        'Property details are provided by the owner. View the property and verify its documents before making an agreement.',
    'الإعلان قيد المراجعة': 'Listing under review',
    'تم تسجيل طلب المعاينة تجريبياً': 'Viewing request saved as a demo',
    'طلب معاينة': 'Request a viewing',
    'وحدة': 'units',
    'الأرض': 'Land',
    'البناء': 'Construction',
    'اكتمال المساهمات:': 'Contribution progress:',
    'قبل الانضمام': 'Before joining',
    'راجع مستندات الأرض وخطة التكلفة وآلية توزيع الوحدات. هذه الصفحة للتعريف بالمشروع فقط، ولا تستقبل أموالاً أو تنشئ التزاماً قانونياً.':
        'Review the land documents, cost plan, and unit allocation method. This page is informational only and does not accept money or create a legal commitment.',
    'المشروع قيد المراجعة': 'Project under review',
    'تم تسجيل اهتمامك تجريبياً — لا توجد مدفوعات داخل التطبيق':
        'Your interest was saved as a demo. No payments are made in the app.',
    'طلب الانضمام': 'Request to join',
    'ابدأ خطوتك التالية': 'Take your next step',
    'أضف إعلان عقار': 'Post a property',
    'اعرض عقارك للمشترين مباشرة': 'Show your property to buyers',
    'أنشئ مشروع شراكة': 'Create a partnership project',
    'شارك تفاصيل الأرض وخطة المشروع': 'Share the land and project plan',
    'تعذر الاتصال بالخادم؛ أُضيف العقار مؤقتاً على هذا الجهاز.':
        'Could not reach the server. The property was added temporarily on this device.',
    'تم رفع الوسائط لكن تعذر حفظ الإعلان. تحقق من اتصال الخادم وحاول مجدداً.':
        'Media uploaded, but the listing could not be saved. Check the server and try again.',
    'تم إرسال الإعلان إلى الخادم وهو قيد المراجعة.':
        'The listing was sent to the server and is under review.',
    'تعذر الاتصال بالخادم؛ أُضيف المشروع مؤقتاً على هذا الجهاز.':
        'Could not reach the server. The project was added temporarily on this device.',
    'تم إرسال المشروع إلى الخادم وهو قيد المراجعة.':
        'The project was sent to the server and is under review.',
    'إنشاء مشروع شراكة': 'Create a partnership project',
    'عرّف بالمشروع وتكاليفه المتوقعة بوضوح. لا يتم تحصيل أموال أو إنشاء التزامات قانونية من خلال هذه النسخة.':
        'Describe the project and expected costs clearly. This version does not collect money or create legal obligations.',
    'بيانات المشروع': 'Project information',
    'اسم المشروع': 'Project name',
    'وصف المشروع وخطته': 'Project description and plan',
    'اكتب وصفاً من ٢٠ حرفاً على الأقل': 'Enter at least 20 characters',
    'الموقع': 'Location',
    'المدينة': 'City',
    'المنطقة': 'District',
    'التكلفة والمشاركون': 'Costs and participants',
    'سعر الأرض بالجنيه': 'Land price (EGP)',
    'تقدير تكلفة البناء بالجنيه': 'Estimated construction cost (EGP)',
    'عدد الوحدات': 'Number of units',
    'عدد الشركاء': 'Number of partners',
    'المدة المتوقعة بالأشهر': 'Estimated duration (months)',
    'الحد الأدنى للمساهمة بالجنيه': 'Minimum contribution (EGP)',
    'الحد الأدنى للمساهمة': 'Minimum contribution',
    'التكاليف تقديرية ويجب مراجعتها مع مختصين. أرفق المستندات والعقود بعد اعتماد آلية التحقق القانونية.':
        'Costs are estimates and should be reviewed by professionals. Add documents and contracts after a legal verification process is established.',
    'حفظ المشروع': 'Save project',
    'هذا الحقل مطلوب': 'This field is required',
    'أدخل رقماً أكبر من صفر': 'Enter a number greater than zero',
    'أدخل عدداً صحيحاً': 'Enter a whole number',
    'إضافة عقار': 'Add a property',
    'أضف تفاصيل واضحة ليسهل على المشتري العثور على عقارك.':
        'Add clear details to help buyers find your property.',
    'المعلومات الأساسية': 'Basic information',
    'عنوان الإعلان': 'Listing title',
    'وصف العقار': 'Property description',
    'صور وفيديو العقار': 'Property photos and video',
    'أضف حتى ١٠ صور أو فيديوهات، بحد أقصى ٢٥ ميجابايت للملف.':
        'Add up to 10 photos or videos, with a 25 MB limit per file.',
    'إضافة صور': 'Add photos',
    'إضافة فيديو': 'Add video',
    'جارٍ رفع الوسائط وحفظ الإعلان...': 'Uploading media and saving listing...',
    'الحد الأقصى ١٠ ملفات للإعلان.': 'A listing can have up to 10 media files.',
    'تعذر رفع الوسائط': 'Could not upload property media',
    'تعذر اختيار الملف': 'Could not select media',
    'حجم الملف أكبر من الحد المسموح به وهو ٢٥ ميجابايت.':
        'The file exceeds the 25 MB per-file limit.',
    'سجّل الدخول قبل رفع صور أو فيديو للعقار.':
        'Sign in before uploading property photos or video.',
    'اكتب وصفاً من ١٠ أحرف على الأقل': 'Enter at least 10 characters',
    'شقة': 'Apartment',
    'أرض': 'Land',
    'الموقع والسعر': 'Location and price',
    'السعر بالجنيه': 'Price (EGP)',
    'المساحة والتقسيم': 'Area and layout',
    'المساحة بالمتر²': 'Area (m²)',
    'عدد الغرف': 'Bedrooms',
    'تأكد من صحة السعر والموقع قبل الحفظ. سيرسل الإعلان إلى المراجعة إذا كان الخادم متصلاً.':
        'Check the price and location before saving. The listing will be sent for review when the server is connected.',
    'حفظ الإعلان': 'Save listing',
    'يجب أن تكون القيمة أكبر من صفر': 'The value must be greater than zero',
    'اللغة': 'Language',
    'العربية': 'Arabic',
    'الإنجليزية': 'English',
    'تغيير اللغة': 'Change language',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
