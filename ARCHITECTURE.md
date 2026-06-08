**Lovers — وثيقة التصميم المعماري والـ API**

مقدمة
------
هذه الوثيقة تشرح بنية مشروع "Lovers" للدردشة الصوتية: قواعد البيانات، الـ Collections، الـ Models، الـ APIs، شاشات Flutter، Controllers، Services، لوحة الإدارة، نظام الصلاحيات، خطة النشر، واقتراح بدائل مجانية.

1) مكونات النظام
-----------------
- Client (Flutter mobile): شاشة تسجيل/ملف/غرف صوتية/منشورات/متجر.
- Backend (Node.js + Express): REST API، Socket.IO، إدارة جلسات، توليد توكن Agora.
- Auth: Firebase Authentication (Phone OTP, Google, Facebook, Apple)، التحقق بالخادم عبر Firebase Admin.
- Database: MongoDB (collections مفصلة أدناه).
- Realtime: Socket.IO مع Redis adapter.
- Voice: Agora SDK (tokens تُولد من الـ backend).
- Notifications: Firebase Cloud Messaging.
- Storage: Firebase Storage (صور، فيديو، مقاطع صوتية).
- Admin Panel: AdminJS متصل بـ Mongoose.
- Logging & Security: Winston, helmet, rate-limit، سجلات كاملة.

2) Collections (قاعدة البيانات)
-------------------------------
- users
  - _id, userId (UUID), uid (Firebase), displayName, email, phoneNumber, avatarUrl, coverUrl,
    level, chargeLevel, activityLevel, gender, age, country, bio,
    followersCount, followingCount, friendsCount,
    giftsReceivedCount, giftsSentCount,
    personalBadge, specialBadges[], vehicles[], frames[], isVerified(boolean), verificationBadge,
    roles[], devices[], settings{}, createdAt, updatedAt, lastActiveAt
  - Indexes: userId (unique), uid, email

- rooms
  - roomId (UUID), title, ownerId, type (public/private/vip/agency), password, capacity, maxCapacity,
    seats[{index,userId,isMuted,isLocked,joinedAt}], moderators[], coOwners[], background, logs[], metadata
  - Indexes: roomId, ownerId

- messages
  - messageId, fromUserId, toUserId, roomId, type(text/image/gif/audio), content, attachments[], translatedText,
    isRead, isDeleted, createdAt
  - Indexes: roomId, fromUserId, toUserId

- gifts
  - sku, name, type, rarity, priceCoins, priceDiamonds, effects, meta

- vehicles
  - sku, name, type, rarity, price, durationDays, meta

- agencies
  - agencyId, name, ownerId, managers[], members[{userId,role}], stats{}, payroll[], tasks[], createdAt

- posts
  - postId, authorId, content, media[], likesCount, commentsCount, hashtags[], createdAt

- tasks (daily/agency)
  - taskId, title, description, type, reward, target, assignedTo[], status

- wallet_transactions
  - txId, userId, type(recharge,withdraw,gift,transfer), amount, currency, relatedId, status, createdAt

- admin_logs
  - logId, adminId, action, targetType, targetId, notes, createdAt

- notifications
  - notifId, userId, title, body, data{}, readAt, createdAt

- devices
  - deviceId, userId, platform, pushToken, lastSeenAt

3) APIs (نموذجية)
------------------
BaseURL: `https://api.example.com`

Auth
- POST /api/auth/firebase { idToken } -> verify, upsert user, return server JWT + user
- POST /api/auth/guest -> create guest user
- POST /api/auth/logout -> revoke server token (optional)
- POST /api/auth/devices/register -> تسجيل جهاز (مع توكن جوجل/آبل)

Users
- GET /api/users/:userId -> ملف المستخدم العام
- PUT /api/users/me -> تحديث الملف الشخصي (avatar, cover, bio, settings)
- GET /api/users/:userId/followers
- POST /api/users/:userId/follow
- POST /api/users/:userId/unfollow
- GET /api/users/search?q=

Rooms
- POST /api/rooms -> إنشاء غرفة (body: title,type,password,capacity)
- GET /api/rooms/:roomId -> بيانات الغرفة
- POST /api/rooms/:roomId/join -> طلب الانضمام (خاصة/محميّة)
- POST /api/rooms/:roomId/leave
- POST /api/rooms/:roomId/mute { userId }
- POST /api/rooms/:roomId/transfer-ownership { newOwnerId }
- GET /api/rooms -> قائمة غرف عامة/ترند

Realtime (Socket.IO events)
- joinRoom { roomId, user }
- leaveRoom { roomId }
- roomMessage { roomId, fromUserId, type, content }
- seat: request/assign/revoke
- admin: kick/ban/log

Messages
- POST /api/messages/private { toUserId, type, content }
- GET /api/messages/private/:userId
- POST /api/messages/translate { messageId, targetLang }
- PATCH /api/messages/:id -> تعديل الرسالة
- DELETE /api/messages/:id -> حذف

Gifts & Vehicles & VIP
- GET /api/store/gifts
- POST /api/gifts/send { toUserId, giftSku, count }
- POST /api/store/vehicles/buy { sku, duration }
- GET /api/vip/levels

Wallet
- POST /api/wallet/recharge -> initiate payment (third-party)
- POST /api/wallet/withdraw -> طلب سحب
- GET /api/wallet/transactions

Admin (protected, roles)
- CRUD endpoints for users/rooms/gifts/agencies/posts
- GET /api/admin/stats/real-time
- POST /api/admin/ban-user { userId }

4) Models, Controllers, Services
--------------------------------
- Models: Mongoose models (users, rooms, messages, gifts, vehicles, agencies, posts, wallets)
- Controllers: كل مجموعة لها Controller (usersController, roomsController, messagesController, giftsController, walletController, adminController)
- Services: integraion services (firebaseAdmin, agoraService token, socketService, storageService, paymentService)

5) شاشات Flutter (قائمة كاملة)
-----------------------------
على مستوى التطبيق:
- Onboarding
- Login (phone OTP, Google, Facebook, Apple, Guest)
- Restore account (phone/email)
- Home (قوائم الغرف، ترند)
- Room List / Discover
- Room Screen (واجهة الصوت، قائمة المقاعد، شات نصي جانبي)
- Profile (عرض/تحرير)
- Followers / Following / Friends
- Gifts Store
- Vehicles Store
- VIP Profile
- Agencies (إنشاء/إدارة)
- Create Room (Public/Private/VIP/Agency)
- Messages (محادثات خاصة)
- Posts Feed (صور/فيديو)
- Create Post
- Wallet (شحن/سحب/التاريخ)
- Settings (الأمان، الأجهزة المسجلة، التوثيق)
- Admin Screens (للمشرفين — يمكن الوصول عبر لوحة ويب)

6) نظام الصلاحيات
------------------
Role-based access control (RBAC):
- Super Admin > Admin > Moderator > User > Guest
- صلاحيات لكل مجموعة: CRUD على الموارد، إدارة غرف، إدارة بلاغات، عزل/حظر
- يتم تخزين الأدوار في حقل `roles` داخل `users` وتتحقق Middleware الخادم منها.

7) الحماية واعتبارات الأمان
---------------------------
- Firebase Authentication كخدمة اعتماد موثوقة (Phone OTP + Social providers).
- التحقق على الخادم: كل طلب حساس يجب أن يحتوي توكن الخادم (JWT) الذي يُوقّع بواسطة `JWT_SECRET` بعد التحقق من Firebase.
- Rate limiting لكل IP وEndpoints الحرجة.
- إدخال التحقق (Joi/celebrate) لكل الدروبات.
- CORS وHelmet.
- تسجيل نشاط كامل Audit logs و Admin logs.
- مراقبة وAlerting: Sentry + Prometheus.

8) خطة النشر (Google Play & App Store)
--------------------------------------
تحضير قبل النشر:
- إكمال إعدادات Firebase (SHA1/sha256 لأندرويد)، إعداد Apple Sign In، إعداد الأيقونات/الصور.
- إنشاء حساب مطور Google Play وApple Developer.
- إعداد ملفات التشفير والأذونات (permission) والخصوصية (privacy policy).
- إعداد In-App Purchases (Google Play Billing & App Store In-App Purchases) إذا كان هناك شحن عملات.

خطوات عامة للنشر:
- Android: إعداد `android/app/build.gradle`، تحديث `packageName`، توقيع الـ APK/AAB، رفع AAB إلى Play Console، ملء Data Safety وContent Rating.
- iOS: إعداد Bundle ID، إعداد Certificates & Provisioning Profiles، تفعيل Push Notifications وBackground Modes، Archive ثم Xcode → App Store Connect.

نصائح:
- قبل النشر قم باختبار end-to-end (auth, payments, Agora calls, push notifications).
- استخدم Track (internal / closed) في Play Console لاختبارات بيتا.

9) خطة التحجيم إلى +1,000,000 مستخدم
-------------------------------------
- Stateless API: استخدم Node.js خلف Load Balancer (NGINX/ALB) مع عدة نسخ (PM2 أو Kubernetes).
- Socket.IO: استخدم Redis adapter، ووزّع Socket.IO عبر cluster/namespace، استخدم Sticky sessions أو nginx stream.
- Database: استخدم MongoDB Atlas مع Sharding وReplicaSets.
- Caching: Redis للـ session، rate-limiting، leaderboards.
- Storage: CDN + S3/Firebase Storage لملفات المستخدمين.
- Media/Transcoding: استخدم خدمة متخصصة أو خدمة سحابية.
- Observability: Prometheus + Grafana + APM + Sentry.

10) بدائل مجانية لبعض الخدمات
------------------------------
- Firebase Auth → بديل مفتوح: Supabase Auth أو Keycloak (self-hosted).
- Agora (مرتبطة بتكلفة) → بدائل مفتوحة: Jitsi (WebRTC), mediasoup, Janus — لكن تحتاج استضافة وصيانة وجودة الصوت قد تختلف.
- Firebase Storage → MinIO (self-hosted) أو S3-compatible.
- FCM → لا بديل بنفس مستوى الاعتمادية، FCM مجاني ولافت.

11) خطوات التنفيذ القادمة (مقترحة بالترتيب)
------------------------------------------
1. إعداد مخزن المفاتيح (Firebase service account, Agora keys).
2. نشر بنية backend الأساسية (docker-compose: mongo, redis, backend).
3. تفعيل Admin panel ومسحح الموارد الأساسية (users, rooms, gifts).
4. تنفيذ تسجيل الدخول في Flutter عبر Firebase Auth.
5. تنفيذ Socket.IO وواجهة الغرف الصوتية (UI) + تكامل Agora.
6. إضافة نظام الهدايا والمحفظة والدفع.
7. اختبارات الأداء وتحسين التحجيم.

مخرجات هذه المرحلة
-------------------
- بنية مشروع قابلة للتوسيع في المجلد `backend/` و`flutter/`.
- نموذج أولي من الـ APIs، نماذج MongoDB، وملفات البدء.

إذا رغبت، أبدأ الآن بالتفصيل العملي لواحد من المسارات التالية (اختر واحد):
- تنفيذ تسجيل Firebase Phone OTP في Flutter مع أمثلة حقيقية.
- تنفيذ توليد توكن Agora وتأمينه عبر backend.
- بناء وحدة الهدايا (CRUD + إرسال هدية مع تأثير).
- بناء لوحة إدارة متكاملة ومشغّلة عبر AdminJS.

