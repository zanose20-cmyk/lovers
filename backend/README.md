Lovers Backend — Quick Start

1) نسخ ملف البيئة وتعديله

```
cp .env.example .env
# ثم املأ القيم مثل MONGO_URI, FIREBASE_SERVICE_ACCOUNT_JSON_PATH, AGORA_APP_ID, AGORA_APP_CERTIFICATE
```

2) تثبيت الحزم وتشغيل الخادم

```
cd backend
npm install
npm run dev
```

3) تشغيل خدمات مساعدة (docker-compose)

```
docker-compose up -d
```

4) تهيئة متجر الهدايا (Seeder)

```
cd backend
npm run seed:gifts
```

هذا السكربت ينشئ أمثلة لهدايا (متحركة، 3D، fullscreen) في قاعدة البيانات لاختبار واجهة المتجر.

5) تهيئة مشرف (Admin user)

```
cd backend
npm run seed:admin
```

هذا ينشئ سجل مستخدم بصلاحيات `admin` و`superadmin` في قاعدة البيانات (لا يغيّر بيانات الدخول للوحة AdminJS التي تعتمد على `ADMIN_EMAIL`/`ADMIN_PASSWORD` في `.env`).

4) ملاحظات أمنية
- خزّن مفاتيح Firebase وAgora في سر آمن (Vault) أثناء الإنتاج.
- فعل تحقق من صحة المدخلات، وضع حدود (rate limiting)، وسجل الأنشطة.

5) إدارة لوحة
- لوحة الإدارة متاحة عبر /admin بعد تسجيل الدخول.

