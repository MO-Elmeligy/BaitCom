# بيت كو (BaitCom)

تطبيق Flutter عربي للسوق العقاري والشراكات. يتضمن التطبيق API أولياً في Node.js وPostgreSQL.

## تشغيل الواجهة

شغّل `flutter run`. إذا لم يكن API متصلاً، ستظهر بيانات المعاينة المحلية.

## تشغيل API

راجع [تعليمات إعداد الـ API](backend/README.md) لإعداد PostgreSQL وPostGIS وتشغيل الخادم.

على Android Emulator استخدم:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

تحتاج المنصات الأخرى إلى عنوان API المناسب لها عبر `API_BASE_URL`. مسارات المستخدم التجريبي متاحة في وضع التطوير فقط. لا يستخدم التطبيق مدفوعات أو يحتفظ بأموال المستخدمين.
