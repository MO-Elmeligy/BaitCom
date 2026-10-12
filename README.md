# بيت كو (BaitCo)

تطبيق Flutter للسوق العقاري والشراكات، يدعم العربية والإنجليزية ويضبط اتجاه العرض والأرقام حسب اللغة. يتضمن التطبيق API أولياً في Node.js وPostgreSQL.

## اللغات

تتبع الواجهة لغة الجهاز إذا كانت العربية أو الإنجليزية. يمكن التبديل بينهما من صفحة «حسابي». إدخالات المستخدمين مثل وصف العقار واسم المدينة تظهر كما كتبها صاحب الإعلان.

## تشغيل الواجهة

شغّل `flutter run`. إذا لم يكن API متصلاً، ستظهر بيانات المعاينة المحلية.

## تشغيل API وقاعدة البيانات محلياً

يتطلب تشغيل الخادم محلياً تثبيت Docker Desktop ثم تشغيل الأمر التالي من مجلد المشروع:

````powershell
docker compose up --build
````

يبدأ هذا الأمر PostgreSQL مع PostGIS ويطبق `backend/schema.sql` عند إنشاء قاعدة البيانات لأول مرة، ثم يشغل الـ API. افحصه عبر `http://localhost:3000/health`. لإيقاف الخدمات استخدم `Ctrl+C`، أو `docker compose down` بعد تشغيلها في الخلفية. تبقى بيانات القاعدة في volume اسمه `bayt_co_data`.

إعدادات Compose الافتراضية مخصصة للتطوير المحلي فقط. لا تستخدمها في بيئة إنتاج أو تفتح منفذ قاعدة البيانات على الإنترنت. لإعداد الخادم مباشرة دون Docker راجع [تعليمات الـ API](backend/README.md).

على Android Emulator استخدم:

````powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
````

لرفع صور وفيديوهات العقارات، أنشئ حساب Cloudinary وأضف `CLOUDINARY_CLOUD_NAME` و`CLOUDINARY_API_KEY` و`CLOUDINARY_API_SECRET` إلى ملف `.env` في جذر المشروع قبل تشغيل Compose. لا تضف السر إلى التطبيق أو Git. يتطلب الرفع تسجيل الدخول بحساب Google، ويسمح بما يصل إلى ١٠ ملفات بحد أقصى ٢٥ ميجابايت لكل ملف. راجع [إعدادات الوسائط في API](backend/README.md#property-photos-and-videos).

## إعداد نسخة الإنتاج

قبل نشر النسخة، انشر الـ API على HTTPS ومرّر عنوانه إلى Flutter باستخدام `--dart-define=API_BASE_URL=https://api.example.com`. عند أول طلب API، ترفض نسخة Release عنوانًا غير HTTPS أو عنوانًا غير مضبوط. على الخادم، اضبط `NODE_ENV=production` و`CORS_ORIGIN` على أصل واجهة الويب المنشورة، ولا تستخدم `*`.

تحتاج المنصات الأخرى إلى عنوان API المناسب لها عبر `API_BASE_URL`. مسارات المستخدم التجريبي متاحة في وضع التطوير فقط. لا يستخدم التطبيق مدفوعات أو يحتفظ بأموال المستخدمين.

## توقيع Android

لم يعد بناء Android Release يستخدم مفتاح Debug. أنشئ مفتاح رفع خاصًا باستخدام keytool -genkeypair -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload. أنشئ android/key.properties واكتب فيه storePassword وkeyPassword وkeyAlias=upload وstoreFile=app/upload-keystore.jks، مع كلمات المرور التي اخترتها. يحتفظ Gradle بالمفتاح محليًا ويتوقف بوضوح إذا كان إعداد التوقيع ناقصًا. ملفات المفتاح وكلمات المرور مستثناة من Git؛ احتفظ بنسخة احتياطية آمنة ولا ترفعها إلى المستودع.
## تسجيل الدخول بحساب Google (Firebase)

يستخدم التطبيق تسجيل الدخول بحساب Google عبر Firebase Authentication؛ لا يرسل التطبيق رسائل SMS ولا يطلب توثيق الهاتف. يُدخل صاحب الإعلان رقم تواصل عند إنشاء إعلان عقار أو مشروع شراكة، ويظهر هذا الرقم للمهتمين. بعد تسجيل الدخول، يرسل التطبيق Firebase ID token إلى الـ API بصيغة Bearer ويتحقق الخادم من التوكن ومزوّد تسجيل الدخول. Android يقرأ إعداد Firebase الافتراضي من `android/app/google-services.json`، بينما تحتاج الويب وiOS إلى إعداداتهما الخاصة كما هو موضح أدناه. عند غياب إعداد Firebase في وضع التطوير يبقى تصفح بيانات المعاينة متاحًا.

1. أنشئ Firebase project وسجّل تطبيق Android بمعرّف `com.realestate.real_estate_app` وتطبيق iOS بمعرّف الحزمة `com.realestate.realEstateApp`.
2. فعّل Google provider من Firebase Authentication.
3. سجّل SHA-1 وSHA-256 لشهادة Android في Firebase، ثم نزّل أحدث `google-services.json` وضعه في `android/app/google-services.json`. يحتاج Google sign-in على Android إلى OAuth client وشهادة صحيحة. لتطبيق iOS أضف `GoogleService-Info.plist` وإعداد URL scheme الخاص بـ Google إلى Runner.
4. للويب، خذ `project ID` و`sender ID` و`API key` و`App ID` من إعدادات Firebase ومرّرها عبر `--dart-define`؛ هذه معرفات إعداد عميل وليست أسرار خادم.

مثال Android في PowerShell (استبدل القيم ببيانات مشروع Firebase الفعلية):

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=FIREBASE_PROJECT_ID=your-project-id --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 --dart-define=FIREBASE_ANDROID_API_KEY=your-android-api-key --dart-define=FIREBASE_ANDROID_APP_ID=1:123456789:android:your-app-id
```

مثال iOS من macOS بعد إعداد API وFirebase:

```sh
flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com --dart-define=FIREBASE_PROJECT_ID=your-project-id --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 --dart-define=FIREBASE_IOS_API_KEY=your-ios-api-key --dart-define=FIREBASE_IOS_APP_ID=1:123456789:ios:your-app-id --dart-define=FIREBASE_IOS_BUNDLE_ID=com.realestate.realEstateApp
```

لواجهة الويب أضف `FIREBASE_WEB_API_KEY` و`FIREBASE_WEB_APP_ID` و`FIREBASE_WEB_AUTH_DOMAIN`، ثم أضف نطاق الموقع إلى Authorized domains في Firebase.

راجع [إعداد Firebase لتطبيق Flutter](https://firebase.google.com/docs/flutter/setup) و[تسجيل الدخول بحساب Google](https://firebase.google.com/docs/auth/flutter/federated-auth).
